-- Stress Tests for 20-Turtle Fleet Simulation

-- Load test framework
local test = require("tests.phase10.test_framework")
local assert = test.assert

-- Initialize performance tracking
local performance_metrics = {
    start_time = os.clock(),
    message_count = 0,
    operation_count = 0,
    memory_peaks = {},
    network_bandwidth = 0
}

-- Mock environment for fleet simulation
_G.os = {
    clock = os.clock,
    getComputerID = function() return math.random(1, 100) end,
    startTimer = function(t) return math.random(1, 1000) end,
    cancelTimer = function() end,
    sleep = function(t) 
        -- Simulate time passing
        performance_metrics.operation_count = performance_metrics.operation_count + 1
    end
}

_G.rednet = {
    send = function(id, msg)
        performance_metrics.message_count = performance_metrics.message_count + 1
        performance_metrics.network_bandwidth = performance_metrics.network_bandwidth + #textutils.serialize(msg)
        return true
    end,
    broadcast = function(msg)
        performance_metrics.message_count = performance_metrics.message_count + 20  -- Simulate broadcast to all
        performance_metrics.network_bandwidth = performance_metrics.network_bandwidth + (#textutils.serialize(msg) * 20)
        return true
    end,
    receive = function(timeout)
        -- Simulate receiving messages
        if math.random() > 0.5 then
            return math.random(1, 20), {type = "heartbeat"}, "ULTIMATE_MINER_V2"
        end
        return nil
    end,
    isOpen = function() return true end
}

_G.parallel = {
    waitForAny = function(...) 
        local funcs = {...}
        for _, func in ipairs(funcs) do
            func()
        end
    end
}

_G.textutils = {
    serialize = function(t)
        -- Simple size estimation
        local size = 0
        local function countSize(obj)
            if type(obj) == "table" then
                size = size + 2  -- {}
                for k, v in pairs(obj) do
                    size = size + #tostring(k) + 1
                    countSize(v)
                end
            else
                size = size + #tostring(obj)
            end
        end
        countSize(t)
        return string.rep("x", size)
    end,
    unserialize = function(s) return {} end
}

_G.collectgarbage = function(action)
    if action == "count" then
        -- Simulate memory usage based on operations
        local base_memory = 500
        local operation_memory = performance_metrics.operation_count * 0.1
        local message_memory = performance_metrics.message_count * 0.05
        return base_memory + operation_memory + message_memory
    elseif action == "collect" then
        -- Simulate some memory being freed
        performance_metrics.operation_count = math.floor(performance_metrics.operation_count * 0.8)
        return 0
    end
end

-- Load optimization modules
local MemoryOptimizer = require("turtle.modules.memory_optimizer")
local NetworkOptimizer = require("turtle.modules.network_optimizer")
local PatternOptimizer = require("turtle.modules.pattern_optimizer")
local PerformanceConfig = require("turtle.modules.performance_config")
local CircularBuffer = require("shared.circular_buffer")

-- Mock Core module
local Core = {
    log = function(level, msg) 
        if level == "ERROR" or level == "CRITICAL" then
            print("[" .. level .. "] " .. msg)
        end
    end,
    emit = function(event, data) end,
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
            local dx = p2.x - p1.x
            local dy = p2.y - p1.y  
            local dz = p2.z - p1.z
            return math.sqrt(dx*dx + dy*dy + dz*dz)
        end
    }
}

package.loaded["turtle.modules.core"] = Core

-- Turtle simulation class
local function createVirtualTurtle(id)
    local turtle = {
        id = id,
        position = {x = math.random(-100, 100), y = 64, z = math.random(-100, 100)},
        fuel = 10000,
        inventory = {},
        status = "idle",
        blocks_mined = 0,
        messages_sent = 0,
        memory_usage = 100,
        path_buffer = CircularBuffer.new(500),
        last_heartbeat = os.clock()
    }
    
    -- Simulate mining operation
    function turtle:mine()
        self.status = "mining"
        self.blocks_mined = self.blocks_mined + 1
        self.fuel = self.fuel - 1
        
        -- Track position in buffer
        self.path_buffer:push({
            x = self.position.x,
            y = self.position.y,
            z = self.position.z,
            time = os.clock()
        })
        
        -- Simulate memory growth
        self.memory_usage = self.memory_usage + math.random(1, 5)
        
        -- Move to next position
        self.position.x = self.position.x + math.random(-1, 1)
        self.position.z = self.position.z + math.random(-1, 1)
    end
    
    -- Send heartbeat
    function turtle:sendHeartbeat(optimized)
        local data = {
            id = self.id,
            pos = self.position,
            fuel = self.fuel,
            status = self.status,
            blocks = self.blocks_mined
        }
        
        if optimized then
            data = NetworkOptimizer.optimizeHeartbeat(data)
        end
        
        rednet.broadcast(data)
        self.messages_sent = self.messages_sent + 1
        self.last_heartbeat = os.clock()
    end
    
    -- Check if needs optimization
    function turtle:needsOptimization()
        return self.memory_usage > 1500 or 
               self.path_buffer:isFull() or
               (os.clock() - self.last_heartbeat) > 30
    end
    
    return turtle
end

-- Fleet stress tests
test.suite("Fleet Stress Test - 20 Turtles")
    .test("should handle 20 concurrent turtles", function()
        -- Initialize optimization modules
        MemoryOptimizer.init()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        -- Create fleet
        local fleet = {}
        for i = 1, 20 do
            fleet[i] = createVirtualTurtle(i)
        end
        
        -- Simulate 1000 operations
        for tick = 1, 1000 do
            for _, turtle in ipairs(fleet) do
                -- Each turtle mines
                turtle:mine()
                
                -- Send heartbeat every 10 ticks
                if tick % 10 == 0 then
                    turtle:sendHeartbeat(true)
                end
                
                -- Check for optimization needs
                if turtle:needsOptimization() then
                    MemoryOptimizer.trackOperation()
                end
            end
            
            -- Fleet-wide optimization every 100 ticks
            if tick % 100 == 0 then
                MemoryOptimizer.performOptimization(5)  -- GC
                NetworkOptimizer.sendBatch()
            end
        end
        
        -- Verify all turtles operated
        for _, turtle in ipairs(fleet) do
            assert.isTrue(turtle.blocks_mined > 0, "Turtle " .. turtle.id .. " should mine blocks")
            assert.isTrue(turtle.messages_sent > 0, "Turtle " .. turtle.id .. " should send messages")
        end
        
        -- Check performance metrics
        local total_messages = performance_metrics.message_count
        assert.isTrue(total_messages > 2000, "Should handle many messages")
        
        -- Calculate message rate
        local duration = os.clock() - performance_metrics.start_time
        local message_rate = total_messages / duration
        
        print(string.format("Message rate: %.2f msg/s", message_rate))
        assert.isTrue(message_rate > 10, "Should maintain good message rate")
    end)
    
    .test("should optimize network traffic under load", function()
        NetworkOptimizer.init()
        
        -- Reset metrics
        performance_metrics.message_count = 0
        performance_metrics.network_bandwidth = 0
        
        -- Create fleet
        local fleet = {}
        for i = 1, 20 do
            fleet[i] = createVirtualTurtle(i)
        end
        
        -- Test without optimization
        local unoptimized_bandwidth = 0
        for i = 1, 100 do
            for _, turtle in ipairs(fleet) do
                turtle:sendHeartbeat(false)
            end
        end
        unoptimized_bandwidth = performance_metrics.network_bandwidth
        
        -- Reset and test with optimization
        performance_metrics.network_bandwidth = 0
        
        for i = 1, 100 do
            for _, turtle in ipairs(fleet) do
                -- Queue messages instead of sending immediately
                NetworkOptimizer.queueMessage(nil, {
                    id = turtle.id,
                    pos = turtle.position,
                    fuel = turtle.fuel,
                    status = turtle.status
                })
            end
            
            -- Batch send every 10 iterations
            if i % 10 == 0 then
                NetworkOptimizer.sendBatch()
            end
        end
        
        local optimized_bandwidth = performance_metrics.network_bandwidth
        
        print(string.format("Bandwidth reduction: %.1f%%", 
            (1 - optimized_bandwidth / unoptimized_bandwidth) * 100))
        
        assert.isTrue(optimized_bandwidth < unoptimized_bandwidth * 0.8,
            "Should reduce bandwidth by at least 20%")
    end)
    
    .test("should handle memory pressure with 20 turtles", function()
        MemoryOptimizer.init()
        PerformanceConfig.init()
        
        -- Create fleet with high memory usage
        local fleet = {}
        for i = 1, 20 do
            local turtle = createVirtualTurtle(i)
            turtle.memory_usage = 1800  -- Start with high memory
            fleet[i] = turtle
        end
        
        -- Track optimization triggers
        local optimization_count = 0
        local original_perform = MemoryOptimizer.performOptimization
        MemoryOptimizer.performOptimization = function(...)
            optimization_count = optimization_count + 1
            return original_perform(...)
        end
        
        -- Simulate operations causing memory pressure
        for tick = 1, 500 do
            -- Update memory usage
            _G.collectgarbage = function(action)
                if action == "count" then
                    -- Calculate total fleet memory
                    local total = 0
                    for _, turtle in ipairs(fleet) do
                        total = total + turtle.memory_usage
                    end
                    return total / 20  -- Average
                end
                return 0
            end
            
            -- Each turtle operates
            for _, turtle in ipairs(fleet) do
                turtle:mine()
                
                -- Simulate memory growth
                if math.random() > 0.7 then
                    turtle.memory_usage = turtle.memory_usage + 10
                end
            end
            
            -- Check memory every 10 ticks
            if tick % 10 == 0 then
                MemoryOptimizer.recordSample()
            end
        end
        
        assert.isTrue(optimization_count > 0, "Should trigger optimizations")
        
        -- Verify adaptive settings were applied
        local memory_percent = collectgarbage("count") / 2048 * 100
        local level, settings = PerformanceConfig.getAdaptiveSettings(memory_percent)
        assert.notNil(settings.action, "Should have optimization action")
    end)
    
    .test("should coordinate pattern optimization across fleet", function()
        PatternOptimizer.init()
        
        -- Create mining fleet
        local fleet = {}
        for i = 1, 20 do
            fleet[i] = createVirtualTurtle(i)
        end
        
        -- Assign different patterns to turtles
        local patterns = {"strip", "branch", "spiral", "quarry"}
        
        -- Simulate mining with patterns
        for tick = 1, 1000 do
            for i, turtle in ipairs(fleet) do
                local pattern = patterns[(i - 1) % 4 + 1]
                
                -- Update pattern stats
                if tick % 50 == 0 then
                    PatternOptimizer.updateStats(pattern, {
                        blocks_mined = turtle.blocks_mined,
                        moves = tick,
                        turns = math.floor(tick / 10),
                        ores = math.floor(turtle.blocks_mined * 0.02),
                        fuel = 10000 - turtle.fuel,
                        time = tick
                    })
                end
                
                -- Mine
                turtle:mine()
            end
        end
        
        -- Get pattern statistics
        local stats = PatternOptimizer.getStats()
        
        -- Verify all patterns have stats
        for _, pattern in ipairs(patterns) do
            assert.notNil(stats.pattern_stats[pattern], 
                "Should have stats for " .. pattern)
        end
        
        -- Get recommendations
        local recommendations = PatternOptimizer.getRecommendations()
        assert.notNil(recommendations, "Should provide recommendations")
    end)
    
    .test("should maintain performance with sustained load", function()
        -- Initialize all systems
        MemoryOptimizer.init()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        -- Track performance over time
        local performance_samples = {}
        
        -- Create fleet
        local fleet = {}
        for i = 1, 20 do
            fleet[i] = createVirtualTurtle(i)
        end
        
        -- Run for extended period
        for minute = 1, 10 do
            local minute_start = os.clock()
            local minute_operations = 0
            
            -- 600 ticks per minute (10 per second)
            for tick = 1, 600 do
                for _, turtle in ipairs(fleet) do
                    turtle:mine()
                    minute_operations = minute_operations + 1
                    
                    -- Periodic activities
                    if tick % 60 == 0 then
                        turtle:sendHeartbeat(true)
                    end
                end
                
                -- Fleet maintenance
                if tick % 100 == 0 then
                    MemoryOptimizer.recordSample()
                    NetworkOptimizer.sendBatch()
                end
            end
            
            -- Record performance
            local minute_duration = os.clock() - minute_start
            local ops_per_second = minute_operations / minute_duration
            
            table.insert(performance_samples, {
                minute = minute,
                ops_per_second = ops_per_second,
                memory = collectgarbage("count")
            })
            
            print(string.format("Minute %d: %.0f ops/s, %.0fKB memory",
                minute, ops_per_second, performance_samples[minute].memory))
        end
        
        -- Verify sustained performance
        local first_minute_ops = performance_samples[1].ops_per_second
        local last_minute_ops = performance_samples[#performance_samples].ops_per_second
        
        -- Performance should not degrade more than 20%
        assert.isTrue(last_minute_ops > first_minute_ops * 0.8,
            "Performance should remain stable")
        
        -- Memory should not grow unbounded
        local max_memory = 0
        for _, sample in ipairs(performance_samples) do
            max_memory = math.max(max_memory, sample.memory)
        end
        
        assert.isTrue(max_memory < 2000, "Memory usage should stay bounded")
    end)

-- Performance benchmark test
test.suite("Performance Benchmarks")
    .test("should measure optimization overhead", function()
        -- Measure baseline operation time
        local baseline_start = os.clock()
        local turtle = createVirtualTurtle(1)
        
        for i = 1, 10000 do
            turtle:mine()
        end
        
        local baseline_time = os.clock() - baseline_start
        
        -- Measure with optimizations
        MemoryOptimizer.init()
        NetworkOptimizer.init()
        PatternOptimizer.init()
        
        local optimized_start = os.clock()
        turtle = createVirtualTurtle(2)
        
        for i = 1, 10000 do
            turtle:mine()
            
            if i % 100 == 0 then
                MemoryOptimizer.trackOperation()
                PatternOptimizer.updateStats("test", {blocks_mined = 100})
            end
        end
        
        local optimized_time = os.clock() - optimized_start
        
        -- Calculate overhead
        local overhead_percent = ((optimized_time - baseline_time) / baseline_time) * 100
        
        print(string.format("Optimization overhead: %.1f%%", overhead_percent))
        
        -- Overhead should be reasonable (less than 10%)
        assert.isTrue(overhead_percent < 10, "Optimization overhead should be minimal")
    end)

-- Run stress tests
print("\n" .. string.rep("=", 40))
print("Running Fleet Stress Tests...")
print(string.rep("=", 40) .. "\n")

local results = test.run({verbose = true})

-- Export detailed results
test.exportResults("/logs/phase10_stress_results.txt")

-- Print performance summary
print("\n" .. string.rep("=", 40))
print("Performance Summary:")
print(string.format("Total operations: %d", performance_metrics.operation_count))
print(string.format("Total messages: %d", performance_metrics.message_count))
print(string.format("Network bandwidth: %.1fKB", performance_metrics.network_bandwidth / 1024))
print(string.format("Test duration: %.2fs", os.clock() - performance_metrics.start_time))
print(string.rep("=", 40))

-- Return success status
return results.failed == 0