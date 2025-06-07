-- Edge Case and Error Recovery Tests for Phase 10

-- Load test framework
local test = require("tests.phase10.test_framework")
local assert = test.assert

-- Mock environment with error simulation
_G.error_simulation = {
    should_fail = false,
    fail_count = 0,
    fail_type = "none"
}

_G.turtle = {
    getFuelLevel = function() 
        if error_simulation.fail_type == "no_fuel" then
            return 0
        end
        return 1000
    end,
    dig = function()
        if error_simulation.should_fail and error_simulation.fail_type == "dig_fail" then
            error_simulation.fail_count = error_simulation.fail_count + 1
            return false
        end
        return true
    end
}

_G.fs = {
    open = function(path, mode)
        if error_simulation.fail_type == "fs_fail" then
            return nil
        end
        return {
            write = function(self, data)
                if error_simulation.fail_type == "write_fail" then
                    error("Write failed")
                end
            end,
            writeLine = function(self, data) self:write(data .. "\n") end,
            close = function() end,
            readAll = function()
                if error_simulation.fail_type == "corrupted_data" then
                    return "corrupted{{{data"
                end
                return "{}"
            end
        }
    end,
    exists = function(path)
        if error_simulation.fail_type == "file_missing" then
            return false
        end
        return true
    end,
    delete = function() end,
    move = function() return true end
}

_G.os = {
    clock = os.clock,
    startTimer = function(t) 
        if error_simulation.fail_type == "timer_fail" then
            return nil
        end
        return math.random(1, 100)
    end,
    cancelTimer = function() end,
    sleep = function() end
}

_G.rednet = {
    send = function(id, msg)
        if error_simulation.fail_type == "network_fail" then
            return false
        end
        return true
    end,
    broadcast = function(msg)
        if error_simulation.fail_type == "network_fail" then
            return false
        end
        return true
    end,
    isOpen = function()
        if error_simulation.fail_type == "modem_fail" then
            return false
        end
        return true
    end
}

_G.textutils = {
    serialize = function(t)
        if error_simulation.fail_type == "serialize_fail" then
            error("Failed to serialize")
        end
        return "{}"
    end,
    unserialize = function(s)
        if error_simulation.fail_type == "unserialize_fail" then
            return nil
        end
        return {}
    end
}

_G.collectgarbage = function(action)
    if action == "count" then
        if error_simulation.fail_type == "memory_critical" then
            return 2000  -- 100% usage
        end
        return 500
    end
    return 0
end

-- Load modules
local MemoryOptimizer = require("turtle.modules.memory_optimizer")
local NetworkOptimizer = require("turtle.modules.network_optimizer")
local PatternOptimizer = require("turtle.modules.pattern_optimizer")
local PerformanceConfig = require("turtle.modules.performance_config")
local CircularBuffer = require("shared.circular_buffer")

-- Mock Core
local Core = {
    log = function(level, msg) end,
    emit = function() end,
    on = function() end,
    deepCopy = function(t)
        if type(t) ~= "table" then return t end
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = Core.deepCopy(v)
        end
        return copy
    end,
    vector = {
        distance = function(p1, p2)
            return math.sqrt((p2.x-p1.x)^2 + (p2.y-p1.y)^2 + (p2.z-p1.z)^2)
        end
    }
}

package.loaded["turtle.modules.core"] = Core

-- Helper to reset error simulation
local function resetErrorSimulation()
    error_simulation.should_fail = false
    error_simulation.fail_count = 0
    error_simulation.fail_type = "none"
end

-- Edge Case Tests
test.suite("Edge Cases - Memory Optimizer")
    .test("should handle critical memory (100% usage)", function()
        resetErrorSimulation()
        error_simulation.fail_type = "memory_critical"
        
        MemoryOptimizer.init()
        
        -- This should trigger emergency optimizations
        local sample = MemoryOptimizer.recordSample()
        
        assert.equals(sample.percentage, 100, "Should report 100% memory")
        
        -- Should still function despite critical memory
        local stats = MemoryOptimizer.getStats()
        assert.notNil(stats, "Should return stats even at critical memory")
    end)
    
    .test("should handle nil module references", function()
        resetErrorSimulation()
        
        -- Temporarily remove global references
        local saved_navigation = _G.Navigation
        local saved_inventory = _G.Inventory
        _G.Navigation = nil
        _G.Inventory = nil
        
        MemoryOptimizer.init()
        
        -- Should not crash when trying to clear caches
        local success, freed, actions = MemoryOptimizer.performOptimization(1)
        assert.isTrue(success, "Should succeed even with missing modules")
        
        -- Restore
        _G.Navigation = saved_navigation
        _G.Inventory = saved_inventory
    end)
    
    .test("should handle empty optimization history", function()
        resetErrorSimulation()
        
        MemoryOptimizer.init()
        
        -- Get recommendations with no history
        local recommendations = MemoryOptimizer.getRecommendations()
        assert.notNil(recommendations, "Should return recommendations array")
        assert.equals(type(recommendations), "table", "Should be a table")
    end)

test.suite("Edge Cases - Network Optimizer")
    .test("should handle network failures gracefully", function()
        resetErrorSimulation()
        NetworkOptimizer.init()
        
        -- Queue messages
        for i = 1, 5 do
            NetworkOptimizer.queueMessage(i, {type = "test", data = i})
        end
        
        -- Simulate network failure
        error_simulation.fail_type = "network_fail"
        
        -- Should not crash on send failure
        assert.doesNotThrow(function()
            NetworkOptimizer.sendBatch()
        end, "Should handle network failure")
        
        resetErrorSimulation()
    end)
    
    .test("should handle extremely large messages", function()
        resetErrorSimulation()
        NetworkOptimizer.init()
        
        -- Create large message
        local large_data = {}
        for i = 1, 1000 do
            large_data[i] = string.rep("x", 100)
        end
        
        -- Should handle queueing
        local queued = NetworkOptimizer.queueMessage(1, large_data)
        assert.isTrue(queued, "Should queue large message")
        
        -- Should attempt compression
        NetworkOptimizer.sendBatch()
        
        local stats = NetworkOptimizer.getStats()
        assert.notNil(stats.bytes_saved, "Should track bytes saved")
    end)
    
    .test("should handle nil messages", function()
        resetErrorSimulation()
        NetworkOptimizer.init()
        
        -- Queue nil message
        local queued = NetworkOptimizer.queueMessage(1, nil)
        assert.isTrue(queued, "Should handle nil message")
        
        -- Send batch
        assert.doesNotThrow(function()
            NetworkOptimizer.sendBatch()
        end, "Should not crash on nil message")
    end)

test.suite("Edge Cases - Pattern Optimizer")
    .test("should handle empty ore positions", function()
        resetErrorSimulation()
        PatternOptimizer.init()
        
        -- Cluster empty ore list
        local clusters = PatternOptimizer.clusterOres({})
        assert.notNil(clusters, "Should return empty cluster list")
        assert.equals(#clusters, 0, "Should have no clusters")
    end)
    
    .test("should handle single movement optimization", function()
        resetErrorSimulation()
        PatternOptimizer.init()
        
        -- Single movement
        local movements = [{x = 0, y = 0, z = 0}]
        local optimized = PatternOptimizer.optimizeMovements(movements)
        
        assert.notNil(optimized, "Should return optimized movements")
        assert.equals(#optimized, 1, "Should keep single movement")
    end)
    
    .test("should handle zero efficiency calculation", function()
        resetErrorSimulation()
        PatternOptimizer.init()
        
        -- No movements, no blocks
        local efficiency = PatternOptimizer.calculateEfficiency({}, 0)
        assert.equals(efficiency, 0, "Should return 0 efficiency")
        
        -- Movements but no blocks
        local movements = [{x=0,y=0,z=0}, {x=1,y=0,z=0}]
        efficiency = PatternOptimizer.calculateEfficiency(movements, 0)
        assert.equals(efficiency, 0, "Should return 0 efficiency for no blocks")
    end)
    
    .test("should handle pattern with no fuel", function()
        resetErrorSimulation()
        error_simulation.fail_type = "no_fuel"
        
        PatternOptimizer.init()
        
        -- Optimize with no fuel
        local options = {length = 100, spacing = 3, strips = 5}
        local optimized = PatternOptimizer.optimizeStripPattern(options)
        
        assert.notNil(optimized, "Should return optimized pattern")
        assert.isTrue(optimized.length < options.length, "Should reduce length for no fuel")
        
        resetErrorSimulation()
    end)

test.suite("Edge Cases - Circular Buffer")
    .test("should handle zero size buffer", function()
        resetErrorSimulation()
        
        local buffer = CircularBuffer.new(0)
        assert.notNil(buffer, "Should create buffer")
        
        -- Try to push
        assert.doesNotThrow(function()
            buffer:push("item")
        end, "Should not crash on push to zero-size buffer")
        
        assert.equals(buffer:size(), 0, "Size should remain 0")
    end)
    
    .test("should handle get with invalid index", function()
        resetErrorSimulation()
        
        local buffer = CircularBuffer.new(5)
        buffer:push("item1")
        
        -- Invalid indices
        assert.isNil(buffer:get(-1), "Should return nil for negative index")
        assert.isNil(buffer:get(0), "Should return nil for zero index")
        assert.isNil(buffer:get(10), "Should return nil for out of bounds index")
    end)
    
    .test("should handle pop from empty buffer", function()
        resetErrorSimulation()
        
        local buffer = CircularBuffer.new(5)
        
        -- Pop from empty
        local item = buffer:pop()
        assert.isNil(item, "Should return nil from empty buffer")
        assert.equals(buffer:size(), 0, "Size should remain 0")
    end)
    
    .test("should handle filter with no matches", function()
        resetErrorSimulation()
        
        local buffer = CircularBuffer.new(10)
        for i = 1, 5 do
            buffer:push(i)
        end
        
        -- Filter with no matches
        local results = buffer:filter(function(item) return item > 10 end)
        assert.notNil(results, "Should return empty array")
        assert.equals(#results, 0, "Should have no matches")
    end)

-- Error Recovery Tests
test.suite("Error Recovery - File System")
    .test("should recover from corrupted data files", function()
        resetErrorSimulation()
        error_simulation.fail_type = "corrupted_data"
        
        MemoryOptimizer.init()
        
        -- Should handle corrupted data gracefully
        local report = MemoryOptimizer.exportReport("/test/report.txt")
        
        -- Even with corrupted reads, should function
        local stats = MemoryOptimizer.getStats()
        assert.notNil(stats, "Should provide stats despite corruption")
        
        resetErrorSimulation()
    end)
    
    .test("should handle file write failures", function()
        resetErrorSimulation()
        error_simulation.fail_type = "write_fail"
        
        MemoryOptimizer.init()
        
        -- Should not crash on write failure
        assert.doesNotThrow(function()
            MemoryOptimizer.exportReport("/test/report.txt")
        end, "Should handle write failure gracefully")
        
        resetErrorSimulation()
    end)
    
    .test("should handle missing files", function()
        resetErrorSimulation()
        error_simulation.fail_type = "file_missing"
        
        -- Code optimizer trying to analyze missing file
        local CodeOptimizer = require("shared.code_optimizer")
        
        local report = CodeOptimizer.analyzeModule("/missing/file.lua")
        assert.isNil(report, "Should return nil for missing file")
        
        resetErrorSimulation()
    end)

test.suite("Error Recovery - Network")
    .test("should recover from serialization failures", function()
        resetErrorSimulation()
        NetworkOptimizer.init()
        
        -- Queue message
        NetworkOptimizer.queueMessage(1, {data = "test"})
        
        -- Simulate serialization failure
        error_simulation.fail_type = "serialize_fail"
        
        -- Should not crash
        assert.doesNotThrow(function()
            NetworkOptimizer.sendBatch()
        end, "Should handle serialization failure")
        
        resetErrorSimulation()
    end)
    
    .test("should handle timer failures", function()
        resetErrorSimulation()
        error_simulation.fail_type = "timer_fail"
        
        NetworkOptimizer.init()
        
        -- Queue message (which tries to start timer)
        assert.doesNotThrow(function()
            NetworkOptimizer.queueMessage(1, {test = "data"})
        end, "Should handle timer failure")
        
        resetErrorSimulation()
    end)
    
    .test("should handle modem failures", function()
        resetErrorSimulation()
        error_simulation.fail_type = "modem_fail"
        
        NetworkOptimizer.init()
        
        -- Try to send with failed modem
        assert.doesNotThrow(function()
            NetworkOptimizer.sendBatch()
        end, "Should handle modem failure")
        
        resetErrorSimulation()
    end)

test.suite("Error Recovery - Memory Critical")
    .test("should perform emergency cleanup at critical memory", function()
        resetErrorSimulation()
        
        MemoryOptimizer.init()
        PatternOptimizer.init()
        
        -- Fill pattern optimizer with data
        for i = 1, 1000 do
            PatternOptimizer.updateStats("test", {
                blocks_mined = i,
                moves = i + 10
            })
        end
        
        -- Simulate critical memory
        error_simulation.fail_type = "memory_critical"
        
        -- Record sample should trigger emergency cleanup
        MemoryOptimizer.recordSample()
        
        -- Should have performed optimizations
        local stats = MemoryOptimizer.getStats()
        assert.isTrue(stats.optimization_count > 0, "Should have optimized")
        
        resetErrorSimulation()
    end)
    
    .test("should gracefully degrade features under memory pressure", function()
        resetErrorSimulation()
        PerformanceConfig.init()
        
        -- Simulate high memory
        error_simulation.fail_type = "memory_critical"
        
        -- Get adaptive settings
        local level, settings = PerformanceConfig.getAdaptiveSettings(95)
        assert.equals(level, "critical", "Should be in critical mode")
        
        -- Apply recommended profile
        if settings.action == "applyLowMemoryProfile" then
            PerformanceConfig.applyLowMemoryProfile()
        end
        
        -- Verify features disabled
        assert.isFalse(PerformanceConfig.isFeatureEnabled("detailed_metrics"),
            "Should disable non-essential features")
        
        resetErrorSimulation()
    end)

test.suite("Boundary Tests")
    .test("should handle maximum values", function()
        resetErrorSimulation()
        
        -- Max size circular buffer
        local buffer = CircularBuffer.new(10000)
        
        -- Fill to max
        for i = 1, 10000 do
            buffer:push(i)
        end
        
        assert.equals(buffer:size(), 10000, "Should handle max size")
        assert.isFull(buffer, "Should be full")
        
        -- One more should wrap
        buffer:push(10001)
        assert.equals(buffer:size(), 10000, "Should maintain max size")
        assert.equals(buffer:get(1), 2, "Should have wrapped correctly")
    end)
    
    .test("should handle minimum values", function()
        resetErrorSimulation()
        
        -- Minimum everything
        local buffer = CircularBuffer.new(1)
        assert.equals(buffer.max_size, 1, "Should handle size 1")
        
        buffer:push("only")
        assert.isFull(buffer, "Should be full with 1 item")
        
        buffer:push("new")
        assert.equals(buffer:peek(), "new", "Should have replaced")
    end)

-- Run all edge case and recovery tests
local results = test.run({verbose = true})

-- Export results
test.exportResults("/logs/phase10_edge_recovery_results.txt")

-- Summary
print("\n" .. string.rep("=", 40))
print("Edge Case & Recovery Test Summary:")
print(string.format("Total: %d, Passed: %d, Failed: %d",
    results.total, results.passed, results.failed))
print(string.rep("=", 40))

-- Return success status
return results.failed == 0