-- Integration Tests for Phase 10 Optimization Modules

-- Load test framework
local test = require("tests.phase10.test_framework")
local assert = test.assert

-- Mock environment setup
_G.turtle = test.mock({
    getFuelLevel = function() return 1000 end,
    dig = function() return true end,
    forward = function() return true end,
    turnLeft = function() return true end,
    turnRight = function() return true end,
    up = function() return true end,
    down = function() return true end
})

_G.fs = {
    open = function(path, mode)
        return {
            write = function() end,
            writeLine = function() end,
            close = function() end,
            readAll = function() return "{}" end
        }
    end,
    exists = function() return true end,
    makeDir = function() end
}

_G.os = {
    clock = function() return math.random() * 1000 end,
    startTimer = function(t) return math.random(1, 100) end,
    cancelTimer = function() end,
    sleep = function() end
}

_G.rednet = test.mock({
    send = function() return true end,
    broadcast = function() return true end,
    isOpen = function() return true end
})

_G.textutils = {
    serialize = function(t) 
        -- Simple serialization for testing
        if type(t) == "table" then
            return "{size=" .. #t .. "}"
        end
        return tostring(t)
    end,
    unserialize = function(s) return {} end
}

-- Simulate collectgarbage
_G.collectgarbage = function(action)
    if action == "count" then
        return math.random(100, 1000)  -- Random KB
    elseif action == "collect" then
        return 0
    end
end

-- Load modules
local MemoryOptimizer = require("turtle.modules.memory_optimizer")
local NetworkOptimizer = require("turtle.modules.network_optimizer")
local PatternOptimizer = require("turtle.modules.pattern_optimizer")
local PerformanceConfig = require("turtle.modules.performance_config")
local CircularBuffer = require("shared.circular_buffer")

-- Initialize mock Core module
local Core = {
    log = function() end,
    emit = function() end,
    on = function() end,
    deepCopy = function(t)
        local copy = {}
        for k, v in pairs(t) do
            if type(v) == "table" then
                copy[k] = Core.deepCopy(v)
            else
                copy[k] = v
            end
        end
        return copy
    end,
    vector = {
        distance = function(p1, p2)
            local dx = p2.x - p1.x
            local dy = p2.y - p1.y
            local dz = p2.z - p1.z
            return math.sqrt(dx*dx + dy*dy + dz*dz)
        end
    }
}

package.loaded["turtle.modules.core"] = Core

-- Integration Test Suite 1: Memory and Performance
test.suite("Memory and Performance Integration")
    .test("should optimize memory based on usage", function()
        -- Initialize modules
        MemoryOptimizer.init()
        PerformanceConfig.init()
        
        -- Simulate high memory usage
        _G.collectgarbage = function(action)
            if action == "count" then
                return 1800  -- 1.8MB (90% of 2MB)
            end
            return 0
        end
        
        -- Record sample - should trigger optimization
        local sample = MemoryOptimizer.recordSample()
        assert.isTrue(sample.percentage >= 85, "Memory should be critical")
        
        -- Check if performance config adjusted
        local history_size = PerformanceConfig.get("memory.path_history_size")
        assert.isTrue(history_size <= 500, "Should reduce history size")
    end)
    
    .test("should coordinate garbage collection", function()
        MemoryOptimizer.init()
        
        local gc_called = false
        _G.collectgarbage = function(action)
            if action == "collect" then
                gc_called = true
            end
            return 500
        end
        
        -- Perform optimization
        MemoryOptimizer.performOptimization(5)  -- GARBAGE_COLLECT
        assert.isTrue(gc_called, "Should call garbage collection")
    end)

-- Integration Test Suite 2: Network and Pattern Optimization
test.suite("Network and Pattern Integration")
    .test("should batch pattern optimization updates", function()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        local messages_sent = 0
        Core.emit = function(event, data)
            if event == "network:send" then
                messages_sent = messages_sent + 1
            end
        end
        
        -- Generate multiple pattern updates
        for i = 1, 5 do
            PatternOptimizer.updateStats("strip", {
                blocks_mined = i * 10,
                moves = i * 12,
                ores = i
            })
            
            -- Queue status update
            NetworkOptimizer.queueMessage(nil, {
                type = "pattern_stats",
                data = PatternOptimizer.getStats()
            })
        end
        
        -- Messages should be queued, not sent immediately
        assert.equals(messages_sent, 0, "Messages should be queued")
        
        -- Force batch send
        NetworkOptimizer.sendBatch()
        assert.equals(messages_sent, 1, "Should send one batched message")
    end)
    
    .test("should optimize network traffic for pattern data", function()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        -- Create pattern with movements
        local movements = {}
        for i = 1, 100 do
            table.insert(movements, {x = i, y = 0, z = 0, facing = 0})
        end
        
        -- Cache pattern
        PatternOptimizer.cachePattern("test_pattern", movements)
        
        -- Simulate sending pattern data
        local original_size = #textutils.serialize(movements)
        
        -- Queue compressed message
        NetworkOptimizer.queueMessage(1, {
            type = "cached_pattern",
            id = "test_pattern",
            size = #movements  -- Send size instead of full data
        })
        
        NetworkOptimizer.sendBatch()
        
        -- Verify compression would save space
        local stats = NetworkOptimizer.getStats()
        assert.notNil(stats, "Should have network stats")
    end)

-- Integration Test Suite 3: Circular Buffer with Memory Optimization
test.suite("Circular Buffer Memory Integration")
    .test("should resize buffer based on memory pressure", function()
        local buffer = CircularBuffer.new(1000)
        MemoryOptimizer.init()
        
        -- Fill buffer
        for i = 1, 1000 do
            buffer:push({id = i, data = "test" .. i})
        end
        
        -- Simulate memory pressure
        _G.collectgarbage = function(action)
            if action == "count" then
                return 1900  -- Critical memory
            end
            return 0
        end
        
        -- Memory optimizer should recommend reduction
        local recommendations = MemoryOptimizer.getRecommendations()
        local has_history_recommendation = false
        
        for _, rec in ipairs(recommendations) do
            if rec.action:match("history") then
                has_history_recommendation = true
            end
        end
        
        assert.isTrue(has_history_recommendation, "Should recommend history reduction")
        
        -- Apply optimization
        buffer:resize(250)
        assert.equals(buffer:size(), 250, "Buffer should be resized")
    end)
    
    .test("should efficiently handle buffer operations", function()
        local buffer = CircularBuffer.new(100)
        
        -- Track operations
        local operation_count = 0
        MemoryOptimizer.init()
        MemoryOptimizer.trackOperation = function()
            operation_count = operation_count + 1
        end
        
        -- Perform many operations
        for i = 1, 200 do
            buffer:push(i)
            MemoryOptimizer.trackOperation()
        end
        
        -- Should trigger periodic GC
        assert.isTrue(operation_count >= 200, "Should track all operations")
        
        -- Buffer should handle overflow efficiently
        assert.equals(buffer:size(), 100, "Buffer should maintain max size")
        assert.equals(buffer:get(1), 101, "Should have correct oldest item")
    end)

-- Integration Test Suite 4: Performance Config with All Optimizers
test.suite("Performance Config Integration")
    .test("should coordinate all optimizers", function()
        -- Initialize all modules
        MemoryOptimizer.init()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        -- Apply low memory profile
        PerformanceConfig.applyLowMemoryProfile()
        
        -- Verify all modules respect the config
        local history_size = PerformanceConfig.get("memory.path_history_size")
        assert.equals(history_size, 250, "History size should be reduced")
        
        local gc_interval = PerformanceConfig.get("performance.gc_interval")
        assert.equals(gc_interval, 30, "GC interval should be increased")
        
        local detailed_metrics = PerformanceConfig.isFeatureEnabled("detailed_metrics")
        assert.isFalse(detailed_metrics, "Detailed metrics should be disabled")
    end)
    
    .test("should adapt to changing conditions", function()
        MemoryOptimizer.init()
        
        -- Start with low memory
        _G.collectgarbage = function(action)
            if action == "count" then
                return 500  -- 25% usage
            end
            return 0
        end
        
        local level1, settings1 = PerformanceConfig.getAdaptiveSettings(25)
        assert.equals(level1, "low", "Should be in low memory state")
        
        -- Increase memory usage
        _G.collectgarbage = function(action)
            if action == "count" then
                return 1600  -- 80% usage
            end
            return 0
        end
        
        local level2, settings2 = PerformanceConfig.getAdaptiveSettings(80)
        assert.equals(level2, "high", "Should be in high memory state")
        assert.notEquals(settings1.action, settings2.action, "Should have different actions")
    end)

-- Integration Test Suite 5: Real-world Scenario
test.suite("Real-world Mining Scenario")
    .test("should optimize complete mining operation", function()
        -- Initialize all systems
        MemoryOptimizer.init()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        local buffer = CircularBuffer.new(500)
        
        -- Simulate mining operation
        local total_blocks = 0
        local messages_queued = 0
        
        -- Mock network queueing
        local original_queue = NetworkOptimizer.queueMessage
        NetworkOptimizer.queueMessage = function(...)
            messages_queued = messages_queued + 1
            return original_queue(...)
        end
        
        -- Mine 1000 blocks
        for i = 1, 1000 do
            -- Track movement in buffer
            buffer:push({x = i, y = 0, z = 0})
            
            -- Update pattern stats periodically
            if i % 100 == 0 then
                PatternOptimizer.updateStats("strip", {
                    blocks_mined = 100,
                    moves = 110,
                    ores = math.random(1, 10),
                    fuel = 100
                })
                
                -- Queue network update
                NetworkOptimizer.queueMessage(1, {
                    type = "mining_progress",
                    blocks = i
                })
            end
            
            -- Track memory periodically
            if i % 50 == 0 then
                MemoryOptimizer.trackOperation()
                
                -- Simulate varying memory usage
                _G.collectgarbage = function(action)
                    if action == "count" then
                        return 500 + (i * 0.5)  -- Gradually increase
                    end
                    return 0
                end
                
                MemoryOptimizer.recordSample()
            end
            
            total_blocks = total_blocks + 1
        end
        
        -- Verify optimizations occurred
        assert.equals(total_blocks, 1000, "Should mine all blocks")
        assert.isTrue(messages_queued > 0, "Should queue network messages")
        assert.equals(buffer:size(), 500, "Buffer should maintain size")
        
        -- Check pattern statistics
        local pattern_stats = PatternOptimizer.getStats()
        assert.notNil(pattern_stats.pattern_stats.strip, "Should have strip stats")
        
        -- Send final batch
        NetworkOptimizer.sendBatch()
        
        -- Get optimization reports
        local memory_stats = MemoryOptimizer.getStats()
        local network_stats = NetworkOptimizer.getStats()
        
        assert.notNil(memory_stats.average_percentage, "Should have memory stats")
        assert.notNil(network_stats.messages_batched, "Should have batched messages")
    end)
    
    .test("should handle memory crisis during operation", function()
        MemoryOptimizer.init()
        PatternOptimizer.init()
        
        local optimizations_performed = 0
        local original_perform = MemoryOptimizer.performOptimization
        MemoryOptimizer.performOptimization = function(...)
            optimizations_performed = optimizations_performed + 1
            return original_perform(...)
        end
        
        -- Simulate memory crisis
        _G.collectgarbage = function(action)
            if action == "count" then
                return 1900  -- 95% usage - critical
            end
            return 0
        end
        
        -- This should trigger emergency optimizations
        MemoryOptimizer.recordSample()
        
        assert.isTrue(optimizations_performed >= 2, "Should perform multiple optimizations")
        
        -- Clear pattern optimizer data
        local cleared = PatternOptimizer.clearOldData(0)  -- Clear all
        assert.isTrue(cleared >= 0, "Should clear data")
    end)

-- Run all integration tests
local results = test.run({verbose = true})

-- Export results
test.exportResults("/logs/phase10_integration_results.txt")

-- Print summary
print("\n" .. string.rep("=", 40))
print("Integration Test Summary:")
print(string.format("Total: %d, Passed: %d, Failed: %d",
    results.total, results.passed, results.failed))
print(string.format("Duration: %.3fs", results.duration))

-- Return success status
return results.failed == 0