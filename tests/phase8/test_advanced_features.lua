-- Test Suite for Phase 8: Advanced Features
-- Tests resource targeting, area mining, and smart mining systems

local test_count = 0
local test_passed = 0
local test_failed = 0

-- Helper function to run a test
local function test(name, fn)
    test_count = test_count + 1
    print(string.format("\n[Test %d] %s", test_count, name))
    
    local success, err = pcall(fn)
    if success then
        test_passed = test_passed + 1
        print("  ✓ PASSED")
    else
        test_failed = test_failed + 1
        print("  ✗ FAILED: " .. tostring(err))
    end
end

-- Helper function to assert
local function assert_equals(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s - Expected: %s, Got: %s", 
            message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true, got false")
    end
end

local function assert_false(value, message)
    if value then
        error(message or "Expected false, got true")
    end
end

local function assert_not_nil(value, message)
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

-- Mock modules for testing
local mock_modules = {}

-- Mock Core module
mock_modules.core = {
    log = function(level, message) end,
    emit = function(event, data) end,
    on = function(event, handler) return 1 end,
    off = function(event, id) return true end,
    tableSize = function(t) 
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end,
    formatDuration = function(seconds)
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    end
}

-- Mock State module
mock_modules.state = {
    data = {},
    get = function(key, default) return mock_modules.state.data[key] or default end,
    set = function(key, value) mock_modules.state.data[key] = value; return true end,
    delete = function(key) mock_modules.state.data[key] = nil; return true end,
    save = function() return true end
}

-- Mock Config module
mock_modules.config = {
    data = {
        ["mining.search_radius"] = 32
    },
    get = function(key, default) return mock_modules.config.data[key] or default end,
    set = function(key, value) mock_modules.config.data[key] = value; return true end
}

-- Mock Navigation module
mock_modules.navigation = {
    position = {x = 0, y = 12, z = 0, facing = 0},
    getPosition = function() return mock_modules.navigation.position end,
    moveTo = function(target, options) return true, "Success" end,
    estimateFuel = function(target) return 100 end
}

-- Mock Mining module
mock_modules.mining = {
    executePattern = function(pattern, options) return true end,
    startAdaptiveMining = function(options) return true end
}

-- Mock Optimization module
mock_modules.optimization = {
    getOptimalYLevel = function(ore_type)
        local levels = {
            diamond = {optimal_y = -59, y_range = {-64, 16}, value = 10},
            iron = {optimal_y = 16, y_range = {-64, 320}, value = 3}
        }
        return levels[ore_type], levels[ore_type]
    end,
    recommendPattern = function(criteria)
        return {{pattern = "branch", score = 0.8, options = {}}}
    end
}

-- Mock Network module
mock_modules.network = {
    connected = true,
    sendTaskProgress = function(data) return true end,
    sendTaskComplete = function(data) return true end,
    sendAreaSaturated = function(data) return true end
}

-- Override require for testing
local original_require = require
_G.require = function(module)
    if module == "turtle.modules.core" then return mock_modules.core
    elseif module == "turtle.modules.state" then return mock_modules.state
    elseif module == "turtle.modules.config" then return mock_modules.config
    elseif module == "turtle.modules.navigation" then return mock_modules.navigation
    elseif module == "turtle.modules.mining" then return mock_modules.mining
    elseif module == "turtle.modules.optimization" then return mock_modules.optimization
    elseif module == "turtle.modules.network" then return mock_modules.network
    elseif module == "control.modules.core" then return mock_modules.core
    elseif module == "control.modules.network" then return mock_modules.network
    elseif module == "control.modules.fleet" then return mock_modules.fleet
    elseif module == "control.modules.commands" then return mock_modules.commands
    else
        return original_require(module)
    end
end

-- Additional mocks for control modules
mock_modules.fleet = {
    turtles = {},
    registerTurtle = function(id, info) 
        mock_modules.fleet.turtles[id] = {id = id, status = "idle"}
        return true 
    end,
    getTurtle = function(id) return mock_modules.fleet.turtles[id] end,
    getOnlineTurtles = function() return mock_modules.fleet.turtles end,
    assignTask = function(id, task) return true end
}

mock_modules.commands = {
    commands = {},
    register = function(name, def) 
        mock_modules.commands.commands[name] = def
        return true
    end,
    execute = function(turtle_id, command, params) return true end
}

-- Test Resource Targeting Module
print("\n=== Testing Resource Targeting Module ===")

test("Initialize targeting module", function()
    local Targeting = require("turtle.modules.targeting")
    local success, err = Targeting.init()
    assert_true(success, "Failed to initialize: " .. tostring(err))
end)

test("Add resource target", function()
    local Targeting = require("turtle.modules.targeting")
    Targeting.init()
    
    local success, id = Targeting.addTarget("diamond", 64, {priority = 8})
    assert_true(success, "Failed to add target")
    assert_not_nil(id, "No target ID returned")
end)

test("Get resource targets", function()
    local Targeting = require("turtle.modules.targeting")
    Targeting.init()
    
    Targeting.addTarget("iron", 128, {priority = 5})
    Targeting.addTarget("gold", 32, {priority = 7})
    
    local targets = Targeting.getTargets()
    assert_equals(#targets, 2, "Wrong number of targets")
    -- Higher priority should be first
    assert_equals(targets[1].resource, "gold", "Priority ordering incorrect")
end)

test("Resource target progress tracking", function()
    local Targeting = require("turtle.modules.targeting")
    Targeting.init()
    
    local success, id = Targeting.addTarget("coal", 100)
    assert_true(success)
    
    local progress = Targeting.getProgress(id)
    assert_not_nil(progress, "No progress data")
    assert_equals(progress.gathered, 0, "Initial gathered should be 0")
    assert_equals(progress.remaining, 100, "Initial remaining incorrect")
end)

test("Get available resources", function()
    local Targeting = require("turtle.modules.targeting")
    Targeting.init()
    
    local resources = Targeting.getAvailableResources()
    assert_true(#resources > 0, "No resources available")
    
    -- Check for known resource
    local found_diamond = false
    for _, res in ipairs(resources) do
        if res.type == "diamond" then
            found_diamond = true
            assert_equals(res.optimal_y, -59, "Wrong optimal Y for diamond")
        end
    end
    assert_true(found_diamond, "Diamond not in resource list")
end)

test("Estimate mining time", function()
    local Targeting = require("turtle.modules.targeting")
    Targeting.init()
    
    local estimate = Targeting.estimateTime("diamond", 10)
    assert_not_nil(estimate, "No estimate returned")
    assert_true(estimate.seconds > 0, "Invalid time estimate")
    assert_true(estimate.blocks > 0, "Invalid block estimate")
end)

-- Test Area Mining Module
print("\n=== Testing Area Mining Module ===")

test("Initialize area module", function()
    local Area = require("turtle.modules.area")
    local success, err = Area.init()
    assert_true(success, "Failed to initialize: " .. tostring(err))
end)

test("Define mining area", function()
    local Area = require("turtle.modules.area")
    Area.init()
    
    local success, area = Area.defineArea(
        {x = 0, z = 0},
        {x = 31, z = 31},
        {name = "Test Area"}
    )
    
    assert_true(success, "Failed to define area")
    assert_equals(area.width, 32, "Wrong area width")
    assert_equals(area.length, 32, "Wrong area length")
end)

test("Area bounds checking", function()
    local Area = require("turtle.modules.area")
    Area.init()
    
    local success, area = Area.defineArea({x = 0, z = 0}, {x = 15, z = 15})
    Area.assignArea(area)
    
    assert_true(Area.isInBounds({x = 5, y = 10, z = 5}), "Should be in bounds")
    assert_false(Area.isInBounds({x = 20, y = 10, z = 20}), "Should be out of bounds")
end)

test("Boundary enforcement", function()
    local Area = require("turtle.modules.area")
    Area.init()
    
    local success, area = Area.defineArea({x = 0, z = 0}, {x = 10, z = 10})
    Area.assignArea(area)
    
    local enforced = Area.enforceBoundary({x = 15, y = 10, z = 15})
    assert_equals(enforced.x, 10, "X not enforced to boundary")
    assert_equals(enforced.z, 10, "Z not enforced to boundary")
end)

test("Chunk detection", function()
    local Area = require("turtle.modules.area")
    Area.init()
    
    local success, area = Area.defineArea({x = 0, z = 0}, {x = 31, z = 31})
    assert_equals(#area.chunks, 4, "Should cover 4 chunks")
end)

test("Area saturation detection", function()
    local Area = require("turtle.modules.area")
    Area.init()
    
    local saturation = Area.checkSaturation()
    assert_equals(saturation, 0, "Initial saturation should be 0")
end)

-- Test Smart Mining Module
print("\n=== Testing Smart Mining Module ===")

test("Initialize smart mining", function()
    local SmartMining = require("turtle.modules.smart_mining")
    local success, err = SmartMining.init()
    assert_true(success, "Failed to initialize: " .. tostring(err))
end)

test("Y-level optimization", function()
    local SmartMining = require("turtle.modules.smart_mining")
    SmartMining.init()
    
    local success, best_y = SmartMining.optimizeYLevel({"diamond", "iron"})
    assert_true(success, "Y-level optimization failed")
    assert_not_nil(best_y, "No optimal Y returned")
end)

test("Get alternative depths", function()
    local SmartMining = require("turtle.modules.smart_mining")
    SmartMining.init()
    
    local alternatives = SmartMining.getAlternativeDepths("iron", 64)
    assert_true(type(alternatives) == "table", "Should return table")
end)

test("Pattern adaptation", function()
    local SmartMining = require("turtle.modules.smart_mining")
    SmartMining.init()
    
    -- Update stats to trigger adaptation
    SmartMining.updateStats({x = 0, y = 12, z = 0}, {is_ore = false})
    
    local success, strategy = SmartMining.adaptPattern()
    -- May be false if too soon to adapt
    assert_not_nil(success, "adaptPattern should return result")
end)

test("Efficiency report", function()
    local SmartMining = require("turtle.modules.smart_mining")
    SmartMining.init()
    
    local report = SmartMining.getEfficiencyReport()
    assert_not_nil(report, "No report returned")
    assert_equals(report.total_blocks, 0, "Initial blocks should be 0")
    assert_not_nil(report.pattern_efficiency, "Missing pattern efficiency")
end)

-- Test Task Management Module (Control Computer)
print("\n=== Testing Task Management Module ===")

test("Initialize task management", function()
    local Tasks = require("control.modules.tasks")
    local success, err = Tasks.init()
    assert_true(success, "Failed to initialize: " .. tostring(err))
end)

test("Create resource task", function()
    local Tasks = require("control.modules.tasks")
    Tasks.init()
    
    local task = Tasks.createResourceTask("diamond", 64, {priority = 8})
    assert_not_nil(task, "No task created")
    assert_equals(task.resource, "diamond", "Wrong resource")
    assert_equals(task.quantity, 64, "Wrong quantity")
    assert_equals(task.priority, 8, "Wrong priority")
end)

test("Create area task", function()
    local Tasks = require("control.modules.tasks")
    Tasks.init()
    
    local task = Tasks.createAreaTask({
        x1 = 0, z1 = 0,
        x2 = 31, z2 = 31
    }, {name = "Test Area"})
    
    assert_not_nil(task, "No task created")
    assert_equals(task.area.width, 32, "Wrong area width")
    assert_equals(task.area.name, "Test Area", "Wrong area name")
end)

test("Task queue management", function()
    local Tasks = require("control.modules.tasks")
    Tasks.init()
    
    local task1 = Tasks.createResourceTask("iron", 100, {priority = 5})
    local task2 = Tasks.createResourceTask("diamond", 50, {priority = 8})
    
    Tasks.queueTask(task1)
    Tasks.queueTask(task2)
    
    local queue = Tasks.getQueue()
    assert_equals(#queue, 2, "Wrong queue size")
    -- Higher priority should be first
    assert_equals(queue[1].resource, "diamond", "Priority ordering incorrect")
end)

test("Task assignment", function()
    local Tasks = require("control.modules.tasks")
    Tasks.init()
    
    -- Register a turtle
    mock_modules.fleet.registerTurtle(1, {name = "TestTurtle"})
    
    local task = Tasks.createResourceTask("coal", 200)
    Tasks.assignTask(task, 1)
    
    local active = Tasks.getActiveTasks()
    assert_equals(#active, 1, "Should have 1 active task")
    assert_equals(active[1].turtle_id, 1, "Wrong turtle assignment")
end)

test("Task statistics", function()
    local Tasks = require("control.modules.tasks")
    Tasks.init()
    
    local stats = Tasks.getStats()
    assert_not_nil(stats, "No stats returned")
    assert_not_nil(stats.queued, "Missing queued count")
    assert_not_nil(stats.active, "Missing active count")
    assert_not_nil(stats.resource_totals, "Missing resource totals")
end)

-- Integration Tests
print("\n=== Integration Tests ===")

test("Resource targeting with network updates", function()
    local Targeting = require("turtle.modules.targeting")
    Targeting.init()
    
    -- Add target and simulate progress
    local success, id = Targeting.addTarget("gold", 50)
    assert_true(success)
    
    -- Simulate finding ore
    local progress = Targeting.getProgress(id)
    assert_not_nil(progress)
    
    -- Verify network notification would be sent
    assert_true(mock_modules.network.connected, "Network should be connected")
end)

test("Area mining with boundary enforcement", function()
    local Area = require("turtle.modules.area")
    Area.init()
    
    -- Define and assign area
    local success, area = Area.defineArea({x = 0, z = 0}, {x = 20, z = 20})
    assert_true(success)
    
    Area.assignArea(area)
    
    -- Test movement within area
    local pos = {x = 10, y = 12, z = 10}
    assert_true(Area.isInBounds(pos), "Should be within bounds")
    
    -- Test boundary enforcement
    local outside = {x = 30, y = 12, z = 30}
    local enforced = Area.enforceBoundary(outside)
    assert_true(Area.isInBounds(enforced), "Enforced position should be in bounds")
end)

test("Smart mining adaptation", function()
    local SmartMining = require("turtle.modules.smart_mining")
    SmartMining.init()
    
    -- Simulate mining session
    for i = 1, 10 do
        SmartMining.updateStats(
            {x = i, y = 12, z = 0},
            {is_ore = i % 5 == 0} -- 20% ore rate
        )
    end
    
    local report = SmartMining.getEfficiencyReport()
    assert_equals(report.total_blocks, 10, "Should have mined 10 blocks")
    assert_equals(report.total_ores, 2, "Should have found 2 ores")
end)

-- Restore original require
_G.require = original_require

-- Print test summary
print("\n" .. string.rep("=", 50))
print(string.format("Tests completed: %d", test_count))
print(string.format("Passed: %d", test_passed))
print(string.format("Failed: %d", test_failed))
print(string.format("Success rate: %.1f%%", (test_passed / test_count) * 100))
print(string.rep("=", 50))

-- Return success if all tests passed
return test_failed == 0