-- Unit Tests for Phase 10 Optimization Modules

-- Load test framework
local test = require("tests.phase10.test_framework")
local assert = test.assert

-- Mock CC:Tweaked APIs
_G.turtle = test.mock({
    getFuelLevel = function() return 1000 end,
    dig = function() return true end,
    forward = function() return true end
})

_G.fs = {
    open = function(path, mode)
        return {
            write = function() end,
            writeLine = function() end,
            close = function() end,
            readAll = function() return "" end
        }
    end,
    exists = function() return true end,
    list = function() return {} end,
    isDir = function() return false end,
    combine = function(a, b) return a .. "/" .. b end
}

_G.os = {
    clock = function() return 0 end,
    startTimer = function() return 1 end,
    cancelTimer = function() end,
    sleep = function() end,
    date = function() return "2024-01-01" end
}

_G.term = {
    isColor = function() return true end
}

_G.textutils = {
    serialize = function(t) return "{}" end,
    unserialize = function(s) return {} end
}

-- Load modules
local MemoryOptimizer = require("turtle.modules.memory_optimizer")
local NetworkOptimizer = require("turtle.modules.network_optimizer")
local PatternOptimizer = require("turtle.modules.pattern_optimizer")
local PerformanceConfig = require("turtle.modules.performance_config")
local CircularBuffer = require("shared.circular_buffer")
local CodeOptimizer = require("shared.code_optimizer")

-- Test Memory Optimizer
test.suite("Memory Optimizer")
    .test("should initialize correctly", function()
        local success, msg = MemoryOptimizer.init()
        assert.isTrue(success, "Initialization should succeed")
        assert.equals(msg, "Memory Optimizer initialized")
    end)
    
    .test("should record memory samples", function()
        MemoryOptimizer.init()
        local sample = MemoryOptimizer.recordSample()
        
        assert.notNil(sample, "Should return memory sample")
        assert.notNil(sample.used, "Sample should have used memory")
        assert.notNil(sample.percentage, "Sample should have percentage")
        assert.notNil(sample.timestamp, "Sample should have timestamp")
    end)
    
    .test("should perform memory optimization", function()
        MemoryOptimizer.init()
        local success, freed, actions = MemoryOptimizer.performOptimization(5) -- GARBAGE_COLLECT
        
        assert.isTrue(success, "Optimization should succeed")
        assert.notNil(freed, "Should return freed memory amount")
        assert.notNil(actions, "Should return actions taken")
    end)
    
    .test("should get memory statistics", function()
        MemoryOptimizer.init()
        MemoryOptimizer.recordSample()
        
        local stats = MemoryOptimizer.getStats()
        assert.notNil(stats.current, "Should have current memory info")
        assert.notNil(stats.average_percentage, "Should have average percentage")
        assert.notNil(stats.module_memory, "Should have module memory info")
    end)
    
    .test("should provide recommendations", function()
        MemoryOptimizer.init()
        local recommendations = MemoryOptimizer.getRecommendations()
        
        assert.notNil(recommendations, "Should return recommendations array")
        assert.equals(type(recommendations), "table", "Recommendations should be a table")
    end)

-- Test Network Optimizer
test.suite("Network Optimizer")
    .test("should initialize correctly", function()
        local success, msg = NetworkOptimizer.init()
        assert.isTrue(success, "Initialization should succeed")
        assert.equals(msg, "Network Optimizer initialized")
    end)
    
    .test("should queue messages for batching", function()
        NetworkOptimizer.init()
        local queued = NetworkOptimizer.queueMessage(1, {type = "test"})
        
        assert.isTrue(queued, "Message should be queued")
    end)
    
    .test("should optimize heartbeat messages", function()
        NetworkOptimizer.init()
        
        local status = {id = 1, fuel = 1000, pos = {x = 0, y = 0, z = 0}}
        local optimized = NetworkOptimizer.optimizeHeartbeat(status)
        
        assert.notNil(optimized, "Should return optimized heartbeat")
        assert.notNil(optimized.type, "Should have message type")
    end)
    
    .test("should process optimized messages", function()
        NetworkOptimizer.init()
        
        local batch = {
            type = "batch",
            messages = [{type = "status"}, {type = "heartbeat"}]
        }
        
        local processed = NetworkOptimizer.processMessage(batch)
        assert.notNil(processed, "Should process batch message")
        assert.equals(#processed, 2, "Should extract all messages")
    end)
    
    .test("should track network statistics", function()
        NetworkOptimizer.init()
        local stats = NetworkOptimizer.getStats()
        
        assert.notNil(stats.messages_sent, "Should track messages sent")
        assert.notNil(stats.bytes_saved, "Should track bytes saved")
        assert.notNil(stats.batch_ratio, "Should calculate batch ratio")
    end)

-- Test Pattern Optimizer
test.suite("Pattern Optimizer")
    .test("should initialize correctly", function()
        local success, msg = PatternOptimizer.init()
        assert.isTrue(success, "Initialization should succeed")
        assert.equals(msg, "Pattern Optimizer initialized")
    end)
    
    .test("should optimize strip pattern", function()
        PatternOptimizer.init()
        
        local options = {length = 50, spacing = 3, strips = 5}
        local optimized = PatternOptimizer.optimizeStripPattern(options)
        
        assert.notNil(optimized, "Should return optimized pattern")
        assert.isTrue(optimized.skip_scanned, "Should enable skip scanned")
        assert.isTrue(optimized.smart_turns, "Should enable smart turns")
    end)
    
    .test("should cluster ore positions", function()
        PatternOptimizer.init()
        
        local ores = [
            {x = 0, y = 0, z = 0},
            {x = 1, y = 0, z = 0},
            {x = 10, y = 0, z = 0}
        ]
        
        local clusters = PatternOptimizer.clusterOres(ores)
        assert.notNil(clusters, "Should return clusters")
        assert.equals(#clusters, 2, "Should create 2 clusters")
    end)
    
    .test("should calculate movement efficiency", function()
        PatternOptimizer.init()
        
        local movements = [
            {x = 0, y = 0, z = 0, facing = 0},
            {x = 1, y = 0, z = 0, facing = 0},
            {x = 2, y = 0, z = 0, facing = 0}
        ]
        
        local efficiency = PatternOptimizer.calculateEfficiency(movements, 3)
        assert.notNil(efficiency, "Should return efficiency")
        assert.isTrue(efficiency > 0, "Efficiency should be positive")
        assert.isTrue(efficiency <= 1, "Efficiency should be <= 1")
    end)
    
    .test("should optimize movement sequences", function()
        PatternOptimizer.init()
        
        local movements = [
            {x = 0, y = 0, z = 0},
            {x = 1, y = 0, z = 0},
            {x = 0, y = 0, z = 0},  -- Backtrack
            {x = 1, y = 0, z = 0}
        ]
        
        local optimized = PatternOptimizer.optimizeMovements(movements)
        assert.notNil(optimized, "Should return optimized movements")
        assert.isTrue(#optimized < #movements, "Should reduce movement count")
    end)

-- Test Performance Config
test.suite("Performance Config")
    .test("should get settings with path", function()
        local value = PerformanceConfig.get("memory.path_history_size", 100)
        assert.equals(value, 500, "Should get correct setting value")
    end)
    
    .test("should set settings with path", function()
        PerformanceConfig.set("test.value", 123)
        local value = PerformanceConfig.get("test.value")
        assert.equals(value, 123, "Should set and get value")
    end)
    
    .test("should apply low memory profile", function()
        PerformanceConfig.applyLowMemoryProfile()
        
        local history_size = PerformanceConfig.get("memory.path_history_size")
        assert.equals(history_size, 250, "Should reduce history size")
        
        local metrics = PerformanceConfig.get("lazy_loading.features.detailed_metrics")
        assert.isFalse(metrics, "Should disable detailed metrics")
    end)
    
    .test("should check feature enabled", function()
        local enabled = PerformanceConfig.isFeatureEnabled("advanced_pathfinding")
        assert.isTrue(enabled, "Advanced pathfinding should be enabled by default")
    end)
    
    .test("should get adaptive settings", function()
        local level, settings = PerformanceConfig.getAdaptiveSettings(85)
        assert.equals(level, "high", "Should return high level for 85%")
        assert.notNil(settings.action, "Should have action recommendation")
    end)

-- Test Circular Buffer
test.suite("Circular Buffer")
    .test("should create new buffer", function()
        local buffer = CircularBuffer.new(10)
        assert.notNil(buffer, "Should create buffer")
        assert.equals(buffer:size(), 0, "New buffer should be empty")
        assert.isTrue(buffer:isEmpty(), "New buffer should be empty")
    end)
    
    .test("should push and get items", function()
        local buffer = CircularBuffer.new(5)
        
        buffer:push("item1")
        buffer:push("item2")
        
        assert.equals(buffer:size(), 2, "Should have 2 items")
        assert.equals(buffer:get(1), "item1", "Should get first item")
        assert.equals(buffer:get(2), "item2", "Should get second item")
    end)
    
    .test("should handle circular overflow", function()
        local buffer = CircularBuffer.new(3)
        
        buffer:push("a")
        buffer:push("b")
        buffer:push("c")
        buffer:push("d")  -- Should overwrite "a"
        
        assert.equals(buffer:size(), 3, "Size should remain at max")
        assert.equals(buffer:get(1), "b", "Oldest should be 'b'")
        assert.equals(buffer:get(3), "d", "Newest should be 'd'")
    end)
    
    .test("should peek at items", function()
        local buffer = CircularBuffer.new(5)
        
        buffer:push("first")
        buffer:push("second")
        
        assert.equals(buffer:peek(), "second", "Should peek at newest")
        assert.equals(buffer:peekOldest(), "first", "Should peek at oldest")
    end)
    
    .test("should filter items", function()
        local buffer = CircularBuffer.new(10)
        
        for i = 1, 5 do
            buffer:push(i)
        end
        
        local evens = buffer:filter(function(item) return item % 2 == 0 end)
        assert.equals(#evens, 2, "Should filter to 2 even numbers")
        assert.contains(evens, 2, "Should contain 2")
        assert.contains(evens, 4, "Should contain 4")
    end)
    
    .test("should resize buffer", function()
        local buffer = CircularBuffer.new(5)
        
        for i = 1, 5 do
            buffer:push(i)
        end
        
        buffer:resize(3)
        assert.equals(buffer:size(), 3, "Should resize to 3 items")
        assert.equals(buffer:get(1), 3, "Should keep most recent items")
    end)

-- Test Code Optimizer
test.suite("Code Optimizer")
    .test("should analyze code for issues", function()
        local code = [[
for i = 1, 10 do
    local str = ""
    str = str .. i
end
        ]]
        
        local issues = CodeOptimizer.analyzeCode(code)
        assert.notNil(issues, "Should return issues")
        assert.isTrue(#issues > 0, "Should find string concatenation issue")
    end)
    
    .test("should generate optimization report", function()
        local code = "local x = 1\nfor i = 1, 10 do\n  x = x + 1\nend"
        local report = CodeOptimizer.generateReport(code, "test.lua")
        
        assert.notNil(report, "Should generate report")
        assert.notNil(report.optimization_score, "Should have optimization score")
        assert.notNil(report.summary, "Should have summary")
    end)
    
    .test("should get memory optimizations", function()
        local code = [[
local big_table = {
    data1 = "value1",
    data2 = "value2",
    data3 = "value3",
    data4 = "value4",
    data5 = "value5"
}
        ]]
        
        local suggestions = CodeOptimizer.getMemoryOptimizations(code)
        assert.notNil(suggestions, "Should return suggestions")
        assert.isTrue(#suggestions > 0, "Should suggest lazy loading for large table")
    end)
    
    .test("should apply CC:Tweaked optimizations", function()
        local code = 'turtle.forward()\nturtle.forward()\nturtle.forward()'
        local optimized = CodeOptimizer.applyCCTweakedOptimizations(code)
        
        assert.notNil(optimized, "Should return optimized code")
        -- In real implementation, it would add caching
    end)

-- Run all tests
local results = test.run({verbose = true})

-- Export results
test.exportResults("/logs/phase10_test_results.txt")

-- Return success status
return results.failed == 0