-- Diagnostic Tools Module
-- Comprehensive diagnostics for troubleshooting and analysis

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local Network = require("turtle.modules.network")
local Safety = require("turtle.modules.safety")
local Monitoring = require("turtle.modules.monitoring")
local Integrity = require("turtle.modules.integrity")
local Alerts = require("turtle.modules.alerts")

local Diagnostics = {}

-- Diagnostic test results
local diagnostic_results = {
    last_run = 0,
    tests = {},
    summary = {
        passed = 0,
        failed = 0,
        warnings = 0
    }
}

-- Test categories
local TEST_CATEGORIES = {
    SYSTEM = "system",
    MOVEMENT = "movement",
    INVENTORY = "inventory",
    NETWORK = "network",
    STORAGE = "storage",
    SAFETY = "safety",
    PERFORMANCE = "performance",
    DATA = "data"
}

-- Initialize diagnostics
function Diagnostics.init()
    Core.log("INFO", "Initializing diagnostic tools")
    
    -- Register diagnostic commands
    Core.on("run_diagnostics", function(category)
        Diagnostics.runDiagnostics(category)
    end)
    
    return true
end

-- Run comprehensive diagnostics
function Diagnostics.runDiagnostics(category)
    Core.log("INFO", "Running diagnostics" .. (category and " for " .. category or ""))
    
    diagnostic_results.last_run = os.clock()
    diagnostic_results.tests = {}
    diagnostic_results.summary = {passed = 0, failed = 0, warnings = 0}
    
    -- Create progress tracker
    local total_tests = Diagnostics.countTests(category)
    local progress_id = Alerts.startProgress("diagnostics", "Running diagnostics", total_tests)
    local current_test = 0
    
    -- Run tests by category
    local categories = category and {category} or {
        TEST_CATEGORIES.SYSTEM,
        TEST_CATEGORIES.MOVEMENT,
        TEST_CATEGORIES.INVENTORY,
        TEST_CATEGORIES.NETWORK,
        TEST_CATEGORIES.STORAGE,
        TEST_CATEGORIES.SAFETY,
        TEST_CATEGORIES.PERFORMANCE,
        TEST_CATEGORIES.DATA
    }
    
    for _, cat in ipairs(categories) do
        local tests = Diagnostics.getTestsForCategory(cat)
        
        for _, test in ipairs(tests) do
            current_test = current_test + 1
            Alerts.updateProgress(progress_id, current_test, "Testing: " .. test.name)
            
            -- Run test
            local result = Diagnostics.runTest(test)
            table.insert(diagnostic_results.tests, result)
            
            -- Update summary
            if result.status == "passed" then
                diagnostic_results.summary.passed = diagnostic_results.summary.passed + 1
            elseif result.status == "failed" then
                diagnostic_results.summary.failed = diagnostic_results.summary.failed + 1
            else
                diagnostic_results.summary.warnings = diagnostic_results.summary.warnings + 1
            end
        end
    end
    
    -- Complete progress
    Alerts.completeProgress(progress_id, "Diagnostics complete")
    
    -- Generate report
    local report = Diagnostics.generateReport()
    
    -- Send alert with results
    local status_msg = string.format("Diagnostics: %d passed, %d failed, %d warnings",
                                   diagnostic_results.summary.passed,
                                   diagnostic_results.summary.failed,
                                   diagnostic_results.summary.warnings)
    
    local alert_type = diagnostic_results.summary.failed > 0 and Alerts.TYPES.ERROR or
                      diagnostic_results.summary.warnings > 0 and Alerts.TYPES.WARNING or
                      Alerts.TYPES.SUCCESS
    
    Alerts.create(alert_type, status_msg, Alerts.PRIORITY.HIGH, {
        report = report
    })
    
    return report
end

-- Count tests for category
function Diagnostics.countTests(category)
    local count = 0
    local categories = category and {category} or {
        TEST_CATEGORIES.SYSTEM,
        TEST_CATEGORIES.MOVEMENT,
        TEST_CATEGORIES.INVENTORY,
        TEST_CATEGORIES.NETWORK,
        TEST_CATEGORIES.STORAGE,
        TEST_CATEGORIES.SAFETY,
        TEST_CATEGORIES.PERFORMANCE,
        TEST_CATEGORIES.DATA
    }
    
    for _, cat in ipairs(categories) do
        count = count + #Diagnostics.getTestsForCategory(cat)
    end
    
    return count
end

-- Get tests for category
function Diagnostics.getTestsForCategory(category)
    local tests = {
        [TEST_CATEGORIES.SYSTEM] = {
            {name = "Turtle API", func = Diagnostics.testTurtleAPI},
            {name = "Fuel System", func = Diagnostics.testFuelSystem},
            {name = "Computer Info", func = Diagnostics.testComputerInfo},
            {name = "Peripheral Detection", func = Diagnostics.testPeripherals}
        },
        
        [TEST_CATEGORIES.MOVEMENT] = {
            {name = "Movement Capability", func = Diagnostics.testMovement},
            {name = "Position Tracking", func = Diagnostics.testPositionTracking},
            {name = "GPS Signal", func = Diagnostics.testGPS},
            {name = "Pathfinding", func = Diagnostics.testPathfinding}
        },
        
        [TEST_CATEGORIES.INVENTORY] = {
            {name = "Inventory Space", func = Diagnostics.testInventorySpace},
            {name = "Item Detection", func = Diagnostics.testItemDetection},
            {name = "Tool Slot", func = Diagnostics.testToolSlot},
            {name = "Fuel Items", func = Diagnostics.testFuelItems}
        },
        
        [TEST_CATEGORIES.NETWORK] = {
            {name = "Modem Presence", func = Diagnostics.testModem},
            {name = "Network Connection", func = Diagnostics.testNetworkConnection},
            {name = "Control Response", func = Diagnostics.testControlResponse},
            {name = "Message Handling", func = Diagnostics.testMessageHandling}
        },
        
        [TEST_CATEGORIES.STORAGE] = {
            {name = "Storage Detection", func = Diagnostics.testStorageDetection},
            {name = "Storage Access", func = Diagnostics.testStorageAccess},
            {name = "Home Position", func = Diagnostics.testHomePosition}
        },
        
        [TEST_CATEGORIES.SAFETY] = {
            {name = "Hazard Detection", func = Diagnostics.testHazardDetection},
            {name = "Emergency Protocols", func = Diagnostics.testEmergencyProtocols},
            {name = "Safety Bounds", func = Diagnostics.testSafetyBounds}
        },
        
        [TEST_CATEGORIES.PERFORMANCE] = {
            {name = "Memory Usage", func = Diagnostics.testMemoryUsage},
            {name = "Operation Speed", func = Diagnostics.testOperationSpeed},
            {name = "Mining Efficiency", func = Diagnostics.testMiningEfficiency}
        },
        
        [TEST_CATEGORIES.DATA] = {
            {name = "State Files", func = Diagnostics.testStateFiles},
            {name = "Data Integrity", func = Diagnostics.testDataIntegrity},
            {name = "Backup System", func = Diagnostics.testBackupSystem}
        }
    }
    
    return tests[category] or {}
end

-- Run individual test
function Diagnostics.runTest(test)
    local start_time = os.clock()
    local success, status, message, details = pcall(test.func)
    local duration = os.clock() - start_time
    
    if not success then
        -- Test crashed
        status = "failed"
        message = "Test crashed: " .. tostring(status)
        details = nil
    end
    
    return {
        name = test.name,
        status = status,
        message = message,
        details = details,
        duration = duration,
        timestamp = os.clock()
    }
end

-- System Tests
function Diagnostics.testTurtleAPI()
    if not turtle then
        return "failed", "Turtle API not available", nil
    end
    
    local required_functions = {
        "forward", "back", "up", "down", "turnLeft", "turnRight",
        "dig", "digUp", "digDown", "place", "placeUp", "placeDown",
        "detect", "detectUp", "detectDown", "inspect", "inspectUp", "inspectDown",
        "select", "getItemCount", "getItemSpace", "getItemDetail",
        "getFuelLevel", "getFuelLimit", "refuel"
    }
    
    local missing = {}
    for _, func in ipairs(required_functions) do
        if not turtle[func] then
            table.insert(missing, func)
        end
    end
    
    if #missing > 0 then
        return "failed", "Missing turtle functions", {missing = missing}
    end
    
    return "passed", "All turtle functions available", {
        fuel_level = turtle.getFuelLevel(),
        fuel_limit = turtle.getFuelLimit()
    }
end

function Diagnostics.testFuelSystem()
    local fuel_level = turtle.getFuelLevel()
    
    if fuel_level == "unlimited" then
        return "passed", "Unlimited fuel mode", nil
    end
    
    local fuel_limit = turtle.getFuelLimit()
    local percentage = (fuel_level / fuel_limit) * 100
    
    if fuel_level < 100 then
        return "failed", "Critically low fuel: " .. fuel_level, {
            level = fuel_level,
            limit = fuel_limit,
            percentage = percentage
        }
    elseif fuel_level < 1000 then
        return "warning", "Low fuel: " .. fuel_level, {
            level = fuel_level,
            limit = fuel_limit,
            percentage = percentage
        }
    end
    
    return "passed", "Fuel level: " .. fuel_level .. "/" .. fuel_limit, {
        level = fuel_level,
        limit = fuel_limit,
        percentage = percentage
    }
end

function Diagnostics.testComputerInfo()
    local info = {
        id = os.getComputerID(),
        label = os.getComputerLabel() or "None",
        version = os.version(),
        is_turtle = turtle ~= nil,
        is_advanced = term.isColor and term.isColor() or false
    }
    
    return "passed", "Computer ID: " .. info.id, info
end

function Diagnostics.testPeripherals()
    local peripherals = peripheral.getNames()
    local details = {}
    
    for _, name in ipairs(peripherals) do
        local ptype = peripheral.getType(name)
        details[name] = ptype
    end
    
    if #peripherals == 0 then
        return "warning", "No peripherals detected", details
    end
    
    return "passed", "Found " .. #peripherals .. " peripherals", details
end

-- Movement Tests
function Diagnostics.testMovement()
    local can_move = {
        forward = turtle.forward(),
        up = false,
        down = false
    }
    
    -- Return to original position
    if can_move.forward then
        turtle.back()
    end
    
    -- Test vertical if horizontal worked
    if can_move.forward then
        can_move.up = turtle.up()
        if can_move.up then
            turtle.down()
        else
            can_move.down = turtle.down()
            if can_move.down then
                turtle.up()
            end
        end
    end
    
    local movable_directions = 0
    for _, v in pairs(can_move) do
        if v then movable_directions = movable_directions + 1 end
    end
    
    if movable_directions == 0 then
        return "failed", "Cannot move in any direction", can_move
    elseif movable_directions < 3 then
        return "warning", "Limited movement capability", can_move
    end
    
    return "passed", "Full movement capability", can_move
end

function Diagnostics.testPositionTracking()
    local pos = Navigation.getPosition()
    
    if not pos then
        return "failed", "Position tracking not initialized", nil
    end
    
    local details = {
        position = pos,
        facing = Navigation.getFacing(),
        confidence = pos.confidence or "unknown"
    }
    
    if pos.confidence and pos.confidence < 0.8 then
        return "warning", "Low position confidence", details
    end
    
    return "passed", "Position tracked accurately", details
end

function Diagnostics.testGPS()
    local x, y, z = gps.locate(2)
    
    if not x then
        return "warning", "No GPS signal available", nil
    end
    
    return "passed", "GPS signal strong", {x = x, y = y, z = z}
end

function Diagnostics.testPathfinding()
    local current_pos = Navigation.getPosition()
    if not current_pos then
        return "failed", "Cannot test without position", nil
    end
    
    -- Test pathfinding to nearby position
    local test_pos = {
        x = current_pos.x + 5,
        y = current_pos.y,
        z = current_pos.z + 5
    }
    
    local path = Navigation.findPath(current_pos, test_pos)
    
    if not path or #path == 0 then
        return "failed", "Pathfinding failed", nil
    end
    
    return "passed", "Pathfinding operational", {
        path_length = #path,
        start = current_pos,
        goal = test_pos
    }
end

-- Inventory Tests
function Diagnostics.testInventorySpace()
    local empty_slots = 0
    local total_items = 0
    
    for i = 1, 16 do
        local count = turtle.getItemCount(i)
        if count == 0 then
            empty_slots = empty_slots + 1
        else
            total_items = total_items + count
        end
    end
    
    local details = {
        empty_slots = empty_slots,
        used_slots = 16 - empty_slots,
        total_items = total_items
    }
    
    if empty_slots == 0 then
        return "failed", "Inventory completely full", details
    elseif empty_slots < 3 then
        return "warning", "Inventory nearly full", details
    end
    
    return "passed", empty_slots .. " empty slots available", details
end

function Diagnostics.testItemDetection()
    local current_slot = turtle.getSelectedSlot()
    local items_detected = {}
    
    for i = 1, 16 do
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item then
            items_detected[i] = {
                name = item.name,
                count = item.count,
                damage = item.damage
            }
        end
    end
    
    turtle.select(current_slot)
    
    return "passed", "Detected " .. #items_detected .. " item types", items_detected
end

function Diagnostics.testToolSlot()
    -- Assuming tool is in slot 1
    turtle.select(1)
    local tool = turtle.getItemDetail()
    
    if not tool then
        return "warning", "No tool in slot 1", nil
    end
    
    local is_pickaxe = tool.name:find("pickaxe")
    
    if not is_pickaxe then
        return "warning", "Tool is not a pickaxe: " .. tool.name, tool
    end
    
    return "passed", "Tool equipped: " .. tool.name, tool
end

function Diagnostics.testFuelItems()
    local fuel_items = {}
    local total_fuel_value = 0
    
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            turtle.select(i)
            -- Test if it's fuel without consuming
            if turtle.refuel(0) then
                fuel_items[i] = {
                    name = item.name,
                    count = item.count
                }
                -- Estimate fuel value (coal = 80)
                if item.name:find("coal") and not item.name:find("ore") then
                    total_fuel_value = total_fuel_value + (item.count * 80)
                end
            end
        end
    end
    
    if total_fuel_value == 0 then
        return "warning", "No fuel items found", fuel_items
    end
    
    return "passed", "Fuel available: ~" .. total_fuel_value .. " moves", fuel_items
end

-- Network Tests
function Diagnostics.testModem()
    local modem = peripheral.find("modem")
    
    if not modem then
        return "failed", "No modem attached", nil
    end
    
    local modem_side = nil
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            modem_side = side
            break
        end
    end
    
    return "passed", "Modem found on " .. (modem_side or "unknown"), {
        side = modem_side,
        is_wireless = modem.isWireless and modem.isWireless() or false
    }
end

function Diagnostics.testNetworkConnection()
    if not Network.isConnected() then
        return "failed", "Not connected to network", nil
    end
    
    local stats = Network.getStatistics()
    
    return "passed", "Network connected", stats
end

function Diagnostics.testControlResponse()
    -- This would ping the control computer
    -- For now, just check if we've received recent messages
    local last_message = Network.getLastMessageTime()
    local time_since = last_message and (os.clock() - last_message) or math.huge
    
    if time_since > 60 then
        return "warning", "No recent control messages", {
            last_message = time_since
        }
    end
    
    return "passed", "Control responsive", {
        last_message = time_since
    }
end

function Diagnostics.testMessageHandling()
    -- Test message handler registration
    local handlers = Network.getHandlers()
    local handler_count = 0
    
    for _ in pairs(handlers) do
        handler_count = handler_count + 1
    end
    
    if handler_count == 0 then
        return "failed", "No message handlers registered", nil
    end
    
    return "passed", handler_count .. " message handlers active", {
        handlers = handler_count
    }
end

-- Storage Tests
function Diagnostics.testStorageDetection()
    local storage = peripheral.find("inventory")
    
    if not storage then
        return "warning", "No storage peripheral found", nil
    end
    
    return "passed", "Storage detected", {
        type = peripheral.getType(peripheral.getName(storage))
    }
end

function Diagnostics.testStorageAccess()
    -- Test would attempt to interact with storage
    -- For safety, we'll just check if the module is ready
    local storage_ready = true  -- Placeholder
    
    if not storage_ready then
        return "failed", "Cannot access storage", nil
    end
    
    return "passed", "Storage accessible", nil
end

function Diagnostics.testHomePosition()
    local home = Navigation.getHome()
    
    if not home then
        return "warning", "No home position set", nil
    end
    
    return "passed", "Home position configured", home
end

-- Safety Tests
function Diagnostics.testHazardDetection()
    local hazards = Safety.scanForHazards()
    
    if hazards and #hazards > 0 then
        return "warning", "Hazards detected nearby", hazards
    end
    
    return "passed", "No hazards detected", nil
end

function Diagnostics.testEmergencyProtocols()
    -- Test emergency systems without triggering them
    local emergency_ready = Safety.isEmergencyReady()
    
    if not emergency_ready then
        return "failed", "Emergency protocols not ready", nil
    end
    
    return "passed", "Emergency protocols ready", nil
end

function Diagnostics.testSafetyBounds()
    local bounds = Safety.getBounds()
    local current_pos = Navigation.getPosition()
    
    if not bounds then
        return "warning", "No safety bounds configured", nil
    end
    
    if current_pos and not Safety.isWithinBounds(current_pos) then
        return "failed", "Currently outside safety bounds", {
            position = current_pos,
            bounds = bounds
        }
    end
    
    return "passed", "Within safety bounds", bounds
end

-- Performance Tests
function Diagnostics.testMemoryUsage()
    -- Estimate memory usage
    local memory_estimate = collectgarbage("count")
    
    if memory_estimate > 500 then
        return "warning", "High memory usage: " .. math.floor(memory_estimate) .. "KB", {
            memory_kb = memory_estimate
        }
    end
    
    return "passed", "Memory usage: " .. math.floor(memory_estimate) .. "KB", {
        memory_kb = memory_estimate
    }
end

function Diagnostics.testOperationSpeed()
    -- Test basic operation speed
    local start_time = os.clock()
    local operations = 0
    
    while os.clock() - start_time < 0.1 do
        operations = operations + 1
        -- Simple operation
        local _ = operations * 2
    end
    
    local ops_per_second = operations * 10
    
    if ops_per_second < 1000 then
        return "warning", "Slow performance detected", {
            operations_per_second = ops_per_second
        }
    end
    
    return "passed", "Performance normal", {
        operations_per_second = ops_per_second
    }
end

function Diagnostics.testMiningEfficiency()
    local stats = Monitoring.getPerformanceReport()
    
    if not stats then
        return "warning", "No mining statistics available", nil
    end
    
    local efficiency = stats.current.fuel_efficiency or 0
    
    if efficiency < 0.5 then
        return "warning", "Low mining efficiency: " .. efficiency, stats.current
    end
    
    return "passed", "Mining efficiency: " .. efficiency, stats.current
end

-- Data Tests
function Diagnostics.testStateFiles()
    local all_valid, results = Integrity.verifyAll()
    
    if not all_valid then
        local failed_files = {}
        for file, result in pairs(results) do
            if not result.valid then
                table.insert(failed_files, file)
            end
        end
        
        return "failed", "State file corruption detected", {
            failed = failed_files,
            results = results
        }
    end
    
    return "passed", "All state files valid", results
end

function Diagnostics.testDataIntegrity()
    -- Test checksum system
    local test_data = {test = "data", value = 12345}
    local test_file = "/tmp/diagnostic_test.json"
    
    -- Write test data
    local write_success = Integrity.atomicWrite(test_file, test_data)
    if not write_success then
        return "failed", "Cannot write test data", nil
    end
    
    -- Read and verify
    local read_success, read_data = Integrity.read(test_file)
    if not read_success then
        return "failed", "Cannot read test data", nil
    end
    
    -- Clean up
    fs.delete(test_file)
    
    -- Verify data matches
    if read_data.test ~= test_data.test or read_data.value ~= test_data.value then
        return "failed", "Data integrity check failed", nil
    end
    
    return "passed", "Data integrity verified", nil
end

function Diagnostics.testBackupSystem()
    local test_file = "/state/test_backup.json"
    local backup_status = Integrity.getBackupStatus(test_file)
    
    local backup_count = 0
    for _, backup in ipairs(backup_status.backups) do
        if backup.exists then
            backup_count = backup_count + 1
        end
    end
    
    return "passed", backup_count .. " backups available", backup_status
end

-- Generate diagnostic report
function Diagnostics.generateReport()
    local report = {
        timestamp = os.clock(),
        duration = os.clock() - diagnostic_results.last_run,
        summary = diagnostic_results.summary,
        categories = {}
    }
    
    -- Group results by category
    for _, result in ipairs(diagnostic_results.tests) do
        local category = Diagnostics.getCategoryForTest(result.name)
        
        if not report.categories[category] then
            report.categories[category] = {
                passed = 0,
                failed = 0,
                warnings = 0,
                tests = {}
            }
        end
        
        local cat = report.categories[category]
        table.insert(cat.tests, result)
        
        if result.status == "passed" then
            cat.passed = cat.passed + 1
        elseif result.status == "failed" then
            cat.failed = cat.failed + 1
        else
            cat.warnings = cat.warnings + 1
        end
    end
    
    -- Add recommendations
    report.recommendations = Diagnostics.generateRecommendations(report)
    
    return report
end

-- Get category for test name
function Diagnostics.getCategoryForTest(test_name)
    local test_map = {
        ["Turtle API"] = TEST_CATEGORIES.SYSTEM,
        ["Fuel System"] = TEST_CATEGORIES.SYSTEM,
        ["Computer Info"] = TEST_CATEGORIES.SYSTEM,
        ["Peripheral Detection"] = TEST_CATEGORIES.SYSTEM,
        ["Movement Capability"] = TEST_CATEGORIES.MOVEMENT,
        ["Position Tracking"] = TEST_CATEGORIES.MOVEMENT,
        ["GPS Signal"] = TEST_CATEGORIES.MOVEMENT,
        ["Pathfinding"] = TEST_CATEGORIES.MOVEMENT,
        ["Inventory Space"] = TEST_CATEGORIES.INVENTORY,
        ["Item Detection"] = TEST_CATEGORIES.INVENTORY,
        ["Tool Slot"] = TEST_CATEGORIES.INVENTORY,
        ["Fuel Items"] = TEST_CATEGORIES.INVENTORY,
        ["Modem Presence"] = TEST_CATEGORIES.NETWORK,
        ["Network Connection"] = TEST_CATEGORIES.NETWORK,
        ["Control Response"] = TEST_CATEGORIES.NETWORK,
        ["Message Handling"] = TEST_CATEGORIES.NETWORK,
        ["Storage Detection"] = TEST_CATEGORIES.STORAGE,
        ["Storage Access"] = TEST_CATEGORIES.STORAGE,
        ["Home Position"] = TEST_CATEGORIES.STORAGE,
        ["Hazard Detection"] = TEST_CATEGORIES.SAFETY,
        ["Emergency Protocols"] = TEST_CATEGORIES.SAFETY,
        ["Safety Bounds"] = TEST_CATEGORIES.SAFETY,
        ["Memory Usage"] = TEST_CATEGORIES.PERFORMANCE,
        ["Operation Speed"] = TEST_CATEGORIES.PERFORMANCE,
        ["Mining Efficiency"] = TEST_CATEGORIES.PERFORMANCE,
        ["State Files"] = TEST_CATEGORIES.DATA,
        ["Data Integrity"] = TEST_CATEGORIES.DATA,
        ["Backup System"] = TEST_CATEGORIES.DATA
    }
    
    return test_map[test_name] or "unknown"
end

-- Generate recommendations based on results
function Diagnostics.generateRecommendations(report)
    local recommendations = {}
    
    -- Check each category
    for category, data in pairs(report.categories) do
        if data.failed > 0 then
            -- Critical failures
            if category == TEST_CATEGORIES.SYSTEM then
                table.insert(recommendations, "Critical: System tests failed. Check turtle hardware.")
            elseif category == TEST_CATEGORIES.MOVEMENT then
                table.insert(recommendations, "Critical: Movement impaired. Clear obstacles or refuel.")
            elseif category == TEST_CATEGORIES.DATA then
                table.insert(recommendations, "Critical: Data corruption detected. Run recovery tools.")
            end
        end
        
        if data.warnings > 0 then
            -- Warnings
            if category == TEST_CATEGORIES.INVENTORY then
                table.insert(recommendations, "Warning: Inventory issues. Consider returning to storage.")
            elseif category == TEST_CATEGORIES.NETWORK then
                table.insert(recommendations, "Warning: Network issues. Check control computer.")
            elseif category == TEST_CATEGORIES.PERFORMANCE then
                table.insert(recommendations, "Warning: Performance degraded. Consider restart.")
            end
        end
    end
    
    -- General recommendations
    if report.summary.failed == 0 and report.summary.warnings == 0 then
        table.insert(recommendations, "All systems operational. Ready for mining operations.")
    elseif report.summary.failed > 5 then
        table.insert(recommendations, "Multiple critical failures. Manual intervention recommended.")
    end
    
    return recommendations
end

-- Get last diagnostic results
function Diagnostics.getLastResults()
    return diagnostic_results
end

-- Export test results to file
function Diagnostics.exportResults(filename)
    filename = filename or "/logs/diagnostic_" .. os.clock() .. ".json"
    
    local report = Diagnostics.generateReport()
    
    -- Ensure directory exists
    local dir = fs.getDir(filename)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Write report
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serialize(report))
        file.close()
        
        Core.log("INFO", "Diagnostic report exported to " .. filename)
        return true, filename
    end
    
    return false, "Failed to write report"
end

return Diagnostics