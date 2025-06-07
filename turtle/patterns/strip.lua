-- Strip Mining Pattern
-- Implements efficient strip mining with configurable spacing

local StripMining = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local Inventory = require("turtle.modules.inventory")
local Safety = require("turtle.modules.safety")
local Storage = require("turtle.modules.storage")
local CONSTANTS = require("shared.constants")

-- Pattern configuration
local DEFAULT_CONFIG = {
    strip_length = 32,      -- Length of each strip
    strip_spacing = 3,      -- Blocks between strips (2 = every 3rd block)
    return_to_start = true, -- Return to starting point when done
    mine_height = 1,        -- 1 = single height, 2 = double height
    torch_spacing = 8,      -- Place torches every N blocks
    check_ores_sides = true,-- Check walls for ores
    vein_mine = true,       -- Mine entire ore veins
    auto_store = true       -- Auto-deposit when full
}

-- Pattern state
local pattern_state = {
    strips_completed = 0,
    blocks_mined = 0,
    ores_found = 0,
    start_position = nil,
    current_strip = 0,
    active = false
}

-- Initialize pattern
function StripMining.init(config)
    -- Merge with default config
    local pattern_config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        pattern_config[k] = config and config[k] or v
    end
    
    -- Save config
    Config.set("strip_mining_config", pattern_config)
    
    -- Reset state
    pattern_state = {
        strips_completed = 0,
        blocks_mined = 0,
        ores_found = 0,
        start_position = Navigation.getPosition(),
        current_strip = 0,
        active = true
    }
    
    Core.info("Strip mining pattern initialized")
    Core.emit("pattern_started", {
        pattern = "strip_mining",
        config = pattern_config
    })
    
    return true
end

-- Mine a single strip
local function mineStrip(length, height)
    local blocks_mined = 0
    local ores_found = 0
    
    for i = 1, length do
        -- Check if we should stop
        if not pattern_state.active then
            return blocks_mined, ores_found, "Pattern stopped"
        end
        
        -- Safety check
        local safe, hazards = Safety.performSafetyCheck()
        if not safe then
            Core.warn("Safety hazard detected during strip mining")
            for _, hazard in ipairs(hazards) do
                Core.warn("  " .. hazard.hazard .. ": " .. hazard.message)
            end
            
            -- Handle critical hazards
            for _, hazard in ipairs(hazards) do
                if hazard.danger_level >= 8 then
                    return blocks_mined, ores_found, "Critical hazard: " .. hazard.hazard
                end
            end
        end
        
        -- Mine forward
        if height == 2 then
            -- Mine 2 high
            Mining.dig("forward")
            Mining.dig("up")
        else
            -- Mine 1 high
            Mining.dig("forward")
        end
        
        -- Move forward
        local moved = Navigation.forward()
        if not moved then
            -- Try to dig and move again
            Mining.dig("forward")
            moved = Navigation.forward()
            if not moved then
                return blocks_mined, ores_found, "Path blocked"
            end
        end
        
        blocks_mined = blocks_mined + 1
        
        -- Check sides for ores if enabled
        local config = Config.get("strip_mining_config")
        if config.check_ores_sides then
            -- Check left
            Navigation.turnLeft()
            local success, block_data = Mining.inspect("forward")
            if success and block_data.is_ore then
                Core.info("Found ore on left: " .. block_data.name)
                ores_found = ores_found + 1
                
                if config.vein_mine then
                    -- Mine the vein
                    local mined = Mining.mineVein(32)
                    blocks_mined = blocks_mined + mined
                else
                    -- Just mine the visible ore
                    Mining.dig("forward")
                    blocks_mined = blocks_mined + 1
                end
            end
            
            -- Check right
            Navigation.turnRight()
            Navigation.turnRight()
            success, block_data = Mining.inspect("forward")
            if success and block_data.is_ore then
                Core.info("Found ore on right: " .. block_data.name)
                ores_found = ores_found + 1
                
                if config.vein_mine then
                    -- Mine the vein
                    local mined = Mining.mineVein(32)
                    blocks_mined = blocks_mined + mined
                else
                    -- Just mine the visible ore
                    Mining.dig("forward")
                    blocks_mined = blocks_mined + 1
                end
            end
            
            -- Face forward again
            Navigation.turnLeft()
        end
        
        -- Check up/down for ores
        local success, block_data = Mining.inspect("up")
        if success and block_data.is_ore then
            Core.info("Found ore above: " .. block_data.name)
            ores_found = ores_found + 1
            if config.vein_mine then
                local current_pos = Navigation.getPosition()
                Navigation.up()
                local mined = Mining.mineVein(32)
                blocks_mined = blocks_mined + mined
                Navigation.moveTo(current_pos)
            else
                Mining.dig("up")
                blocks_mined = blocks_mined + 1
            end
        end
        
        success, block_data = Mining.inspect("down")
        if success and block_data.is_ore then
            Core.info("Found ore below: " .. block_data.name)
            ores_found = ores_found + 1
            if config.vein_mine then
                local current_pos = Navigation.getPosition()
                Navigation.down()
                local mined = Mining.mineVein(32)
                blocks_mined = blocks_mined + mined
                Navigation.moveTo(current_pos)
            else
                Mining.dig("down")
                blocks_mined = blocks_mined + 1
            end
        end
        
        -- Place torch if needed
        if config.torch_spacing > 0 and i % config.torch_spacing == 0 then
            placeTorch()
        end
        
        -- Check inventory
        if Inventory.getFreeSlots() < 2 then
            if config.auto_store then
                -- Try portable storage first
                local has_portable = Storage.hasPortableStorage()
                if has_portable then
                    Core.info("Using portable storage")
                    Storage.usePortableStorage("down")
                else
                    -- Try local storage
                    local stored = Storage.storeItems()
                    if not stored and Inventory.getFreeSlots() < 1 then
                        -- Need to return to base
                        Core.warn("Inventory full, returning to storage")
                        local current_pos = Navigation.getPosition()
                        Storage.returnToStorage()
                        Storage.returnFromStorage()
                        Navigation.moveTo(current_pos)
                    end
                end
            else
                -- Just make space
                Inventory.makeSpace(4)
            end
        end
        
        -- Refuel if needed
        if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 500 then
            Inventory.consumeFuel(1000)
        end
    end
    
    return blocks_mined, ores_found, "Strip complete"
end

-- Place a torch
local function placeTorch()
    -- Find torch in inventory
    local torch_slot = Inventory.findItem("minecraft:torch")
    if not torch_slot then
        Core.debug("No torches available")
        return false
    end
    
    -- Place torch behind us
    turtle.select(torch_slot)
    Navigation.turnRight()
    Navigation.turnRight()
    turtle.place()
    Navigation.turnRight()
    Navigation.turnRight()
    
    return true
end

-- Execute strip mining pattern
function StripMining.execute(num_strips)
    num_strips = num_strips or 1
    local config = Config.get("strip_mining_config")
    
    Core.info("Starting strip mining: " .. num_strips .. " strips")
    pattern_state.start_position = Navigation.getPosition()
    
    for strip = 1, num_strips do
        pattern_state.current_strip = strip
        Core.info("Mining strip " .. strip .. "/" .. num_strips)
        
        -- Mine the strip
        local mined, ores, status = mineStrip(config.strip_length, config.mine_height)
        pattern_state.blocks_mined = pattern_state.blocks_mined + mined
        pattern_state.ores_found = pattern_state.ores_found + ores
        
        Core.info("Strip " .. strip .. " complete: " .. mined .. " blocks, " .. ores .. " ores")
        
        if status ~= "Strip complete" then
            Core.warn("Strip mining stopped: " .. status)
            break
        end
        
        -- Return to start of strip
        Navigation.turnRight()
        Navigation.turnRight()
        for i = 1, config.strip_length do
            Navigation.forward()
        end
        Navigation.turnRight()
        Navigation.turnRight()
        
        -- Move to next strip position if not the last one
        if strip < num_strips then
            -- Move to the side for next strip
            Navigation.turnRight()
            
            -- Move over with spacing
            for i = 1, config.strip_spacing + 1 do
                Mining.digMove("forward")
            end
            
            Navigation.turnLeft()
        end
        
        pattern_state.strips_completed = strip
    end
    
    -- Return to start if configured
    if config.return_to_start and pattern_state.start_position then
        Core.info("Returning to start position")
        Navigation.moveTo(pattern_state.start_position)
    end
    
    pattern_state.active = false
    
    -- Report results
    local results = {
        strips_completed = pattern_state.strips_completed,
        blocks_mined = pattern_state.blocks_mined,
        ores_found = pattern_state.ores_found,
        efficiency = pattern_state.blocks_mined > 0 and 
                    (pattern_state.ores_found / pattern_state.blocks_mined * 100) or 0
    }
    
    Core.info("Strip mining complete:")
    Core.info("  Strips: " .. results.strips_completed)
    Core.info("  Blocks mined: " .. results.blocks_mined)
    Core.info("  Ores found: " .. results.ores_found)
    Core.info("  Efficiency: " .. string.format("%.1f%%", results.efficiency))
    
    Core.emit("pattern_complete", {
        pattern = "strip_mining",
        results = results
    })
    
    return true, results
end

-- Stop the pattern
function StripMining.stop()
    pattern_state.active = false
    Core.info("Strip mining pattern stopped")
    return true
end

-- Get pattern status
function StripMining.getStatus()
    return {
        active = pattern_state.active,
        current_strip = pattern_state.current_strip,
        strips_completed = pattern_state.strips_completed,
        blocks_mined = pattern_state.blocks_mined,
        ores_found = pattern_state.ores_found,
        efficiency = pattern_state.blocks_mined > 0 and 
                    (pattern_state.ores_found / pattern_state.blocks_mined * 100) or 0
    }
end

-- Get pattern info
function StripMining.getInfo()
    return {
        name = "Strip Mining",
        description = "Efficient mining pattern with parallel strips",
        configurable = {
            strip_length = "Length of each mining strip",
            strip_spacing = "Blocks between strips",
            return_to_start = "Return to starting position",
            mine_height = "1 for single, 2 for double height",
            torch_spacing = "Place torches every N blocks",
            check_ores_sides = "Check walls for ores",
            vein_mine = "Mine entire ore veins",
            auto_store = "Auto-deposit when inventory full"
        }
    }
end

return StripMining