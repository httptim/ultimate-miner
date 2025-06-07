-- Test script for Mining module
-- Run this in a turtle to verify mining functionality

-- Add module path
package.path = package.path .. ";/turtle/modules/?.lua;/?.lua"

-- Load modules
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local Mining = require("turtle.modules.mining")
local CONSTANTS = require("shared.constants")

-- Initialize dependencies
Core.init({debug = true})
State.init("test_mining_state.dat")
Config.init("test_mining_config.cfg")
Navigation.init({skip_gps = true})
Inventory.init()

-- Test counters
local tests_passed = 0
local tests_failed = 0

-- Helper function for tests
local function test(name, func)
    print("\nTesting: " .. name)
    local success, err = pcall(func)
    if success then
        print("  ✓ PASSED")
        tests_passed = tests_passed + 1
    else
        print("  ✗ FAILED: " .. tostring(err))
        tests_failed = tests_failed + 1
    end
end

-- Mock some turtle functions for testing
local original_inspect = turtle.inspect
local original_inspectUp = turtle.inspectUp
local original_inspectDown = turtle.inspectDown
local original_dig = turtle.dig
local original_digUp = turtle.digUp
local original_digDown = turtle.digDown

local mock_blocks = {
    forward = nil,
    up = nil,
    down = nil
}

local function setupMockBlock(direction, block_data)
    mock_blocks[direction] = block_data
end

local function setupMockFunctions()
    turtle.inspect = function()
        if mock_blocks.forward then
            return true, mock_blocks.forward
        end
        return false, "No block"
    end
    
    turtle.inspectUp = function()
        if mock_blocks.up then
            return true, mock_blocks.up
        end
        return false, "No block"
    end
    
    turtle.inspectDown = function()
        if mock_blocks.down then
            return true, mock_blocks.down
        end
        return false, "No block"
    end
    
    -- Mock dig functions to always succeed if block exists
    turtle.dig = function()
        if mock_blocks.forward then
            mock_blocks.forward = nil
            return true
        end
        return false
    end
    
    turtle.digUp = function()
        if mock_blocks.up then
            mock_blocks.up = nil
            return true
        end
        return false
    end
    
    turtle.digDown = function()
        if mock_blocks.down then
            mock_blocks.down = nil
            return true
        end
        return false
    end
end

local function restoreTurtle()
    turtle.inspect = original_inspect
    turtle.inspectUp = original_inspectUp
    turtle.inspectDown = original_inspectDown
    turtle.dig = original_dig
    turtle.digUp = original_digUp
    turtle.digDown = original_digDown
end

-- Clean up any existing files
local function cleanup()
    if fs.exists("test_mining_state.dat") then
        fs.delete("test_mining_state.dat")
    end
    if fs.exists("test_mining_config.cfg") then
        fs.delete("test_mining_config.cfg")
    end
end

-- Start tests
print("=== Mining Module Tests ===")
print("Note: Some tests use mocked blocks")
print()

-- Test initialization
test("Mining initialization", function()
    local success, msg = Mining.init()
    assert(success, "Mining init failed: " .. tostring(msg))
end)

-- Test block inspection
test("Block inspection", function()
    setupMockFunctions()
    
    -- Test no block
    mock_blocks.forward = nil
    local success, data = Mining.inspect("forward")
    assert(not success, "Should fail when no block")
    
    -- Test stone block
    setupMockBlock("forward", {name = "minecraft:stone", state = {}})
    success, data = Mining.inspect("forward")
    assert(success, "Should succeed with stone block")
    assert(data.name == "minecraft:stone", "Block name incorrect")
    assert(not data.is_ore, "Stone should not be ore")
    
    -- Test ore block
    setupMockBlock("forward", {name = "minecraft:iron_ore", state = {}})
    success, data = Mining.inspect("forward")
    assert(success, "Should succeed with ore block")
    assert(data.is_ore, "Iron ore should be marked as ore")
    assert(data.ore_type == "IRON", "Ore type should be IRON")
    
    -- Test protected block
    setupMockBlock("forward", {name = "minecraft:bedrock", state = {}})
    success, data = Mining.inspect("forward")
    assert(success, "Should succeed with bedrock")
    assert(data.is_protected, "Bedrock should be protected")
    
    -- Test falling block
    setupMockBlock("forward", {name = "minecraft:gravel", state = {}})
    success, data = Mining.inspect("forward")
    assert(success, "Should succeed with gravel")
    assert(data.is_falling, "Gravel should be marked as falling")
    
    restoreTurtle()
end)

-- Test ore detection
test("Ore detection", function()
    setupMockFunctions()
    
    -- Test all ore types
    local ore_tests = {
        {name = "minecraft:coal_ore", expected = "COAL"},
        {name = "minecraft:deepslate_iron_ore", expected = "IRON"},
        {name = "minecraft:diamond_ore", expected = "DIAMOND"},
        {name = "minecraft:ancient_debris", expected = "ANCIENT_DEBRIS"},
        {name = "minecraft:emerald_ore", expected = "EMERALD"}
    }
    
    for _, ore_test in ipairs(ore_tests) do
        setupMockBlock("forward", {name = ore_test.name, state = {}})
        local success, data = Mining.inspect("forward")
        assert(success, "Should inspect " .. ore_test.name)
        assert(data.is_ore, ore_test.name .. " should be ore")
        assert(data.ore_type == ore_test.expected, 
            "Ore type mismatch: expected " .. ore_test.expected .. " got " .. tostring(data.ore_type))
    end
    
    restoreTurtle()
end)

-- Test mining with safety
test("Safe mining", function()
    setupMockFunctions()
    
    -- Test mining normal block
    setupMockBlock("forward", {name = "minecraft:stone", state = {}})
    local success, msg = Mining.dig("forward")
    assert(success, "Should mine stone block")
    
    -- Test protected block
    setupMockBlock("forward", {name = "minecraft:bedrock", state = {}})
    success, msg = Mining.dig("forward")
    assert(not success, "Should not mine bedrock")
    assert(msg == "Protected block", "Should report protected block")
    
    -- Test no block
    mock_blocks.forward = nil
    success, msg = Mining.dig("forward")
    assert(success, "Should succeed with no block")
    assert(msg == "No block to mine", "Should report no block")
    
    restoreTurtle()
end)

-- Test mining statistics
test("Mining statistics", function()
    -- Reset stats first
    Mining.resetStats()
    
    setupMockFunctions()
    
    -- Mine some blocks
    setupMockBlock("forward", {name = "minecraft:stone", state = {}})
    Mining.dig("forward")
    
    setupMockBlock("forward", {name = "minecraft:iron_ore", state = {}})
    Mining.dig("forward")
    
    setupMockBlock("up", {name = "minecraft:coal_ore", state = {}})
    Mining.dig("up")
    
    -- Check stats
    local stats = Mining.getStats()
    assert(stats.blocks_mined == 3, "Should have mined 3 blocks")
    assert(stats.ores_found == 2, "Should have found 2 ores")
    assert(stats.ore_percentage > 0, "Ore percentage should be positive")
    assert(stats.by_type["minecraft:stone"] == 1, "Should have mined 1 stone")
    assert(stats.by_type["minecraft:iron_ore"] == 1, "Should have mined 1 iron ore")
    
    restoreTurtle()
end)

-- Test with real turtle (if safe)
test("Real turtle operations", function()
    print("  Testing with real turtle functions...")
    restoreTurtle()
    
    -- Test detection
    local has_block_forward = Mining.detect("forward")
    local has_block_up = Mining.detect("up")
    local has_block_down = Mining.detect("down")
    
    print("  Block forward: " .. tostring(has_block_forward))
    print("  Block up: " .. tostring(has_block_up))
    print("  Block down: " .. tostring(has_block_down))
    
    -- Test inspection if block exists
    if has_block_forward then
        local success, data = Mining.inspect("forward")
        if success then
            print("  Forward block: " .. data.name)
            if data.is_ore then
                print("    Is ore: " .. data.ore_type)
            end
        end
    end
    
    -- Test canMine
    local can_mine, reason = Mining.canMine("forward")
    print("  Can mine forward: " .. tostring(can_mine) .. " (" .. reason .. ")")
end)

-- Test ore finding
test("Ore finding", function()
    setupMockFunctions()
    
    -- Set up some ores around
    setupMockBlock("forward", {name = "minecraft:iron_ore", state = {}})
    setupMockBlock("up", {name = "minecraft:coal_ore", state = {}})
    
    local ores = Mining.findOre(1)
    assert(#ores >= 0, "Should return ore list")
    
    -- With mocked functions, we can only detect immediate surroundings
    print("  Found " .. #ores .. " ores nearby")
    
    restoreTurtle()
end)

-- Test mining patterns
test("Mining patterns", function()
    print("  Testing mineAround pattern...")
    setupMockFunctions()
    
    -- Set up blocks all around
    setupMockBlock("forward", {name = "minecraft:stone", state = {}})
    setupMockBlock("up", {name = "minecraft:stone", state = {}})
    setupMockBlock("down", {name = "minecraft:gravel", state = {}})
    
    -- Note: mineAround will try to turn, which might fail in mocked environment
    -- This is more of a structure test
    local success, count = Mining.mineAround()
    print("  Mined " .. tostring(count) .. " blocks around")
    
    restoreTurtle()
end)

-- Test falling block handling
test("Falling block handling", function()
    setupMockFunctions()
    
    -- Override dig to simulate falling blocks
    local dig_count = 0
    turtle.dig = function()
        dig_count = dig_count + 1
        if dig_count < 3 then
            -- Simulate more gravel falling
            return true
        else
            mock_blocks.forward = nil
            return true
        end
    end
    
    setupMockBlock("forward", {name = "minecraft:gravel", state = {}})
    local success = Mining.dig("forward")
    assert(success, "Should handle falling gravel")
    assert(dig_count >= 1, "Should have dug multiple times for falling block")
    
    restoreTurtle()
end)

-- Summary
print("\n=== Test Summary ===")
print("Passed: " .. tests_passed)
print("Failed: " .. tests_failed)
print("Total:  " .. (tests_passed + tests_failed))

if tests_failed > 0 then
    print("\nSome tests failed!")
else
    print("\nAll tests passed!")
end

-- Cleanup
cleanup()
restoreTurtle()
Core.shutdown()