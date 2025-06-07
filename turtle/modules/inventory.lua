-- Inventory Management Module
-- Handles item management, classification, and storage operations

local Inventory = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local inventory_cache = {}
local last_scan_time = 0
local scan_interval = 1000 -- 1 second

-- Item classification patterns
local ITEM_PATTERNS = {
    -- Ores (both stone and deepslate variants)
    ore = {
        "minecraft:coal_ore",
        "minecraft:deepslate_coal_ore",
        "minecraft:iron_ore",
        "minecraft:deepslate_iron_ore",
        "minecraft:copper_ore",
        "minecraft:deepslate_copper_ore",
        "minecraft:gold_ore",
        "minecraft:deepslate_gold_ore",
        "minecraft:redstone_ore",
        "minecraft:deepslate_redstone_ore",
        "minecraft:emerald_ore",
        "minecraft:deepslate_emerald_ore",
        "minecraft:lapis_ore",
        "minecraft:deepslate_lapis_ore",
        "minecraft:diamond_ore",
        "minecraft:deepslate_diamond_ore",
        "minecraft:ancient_debris",
        -- Raw ore items
        "minecraft:raw_iron",
        "minecraft:raw_copper",
        "minecraft:raw_gold",
        "minecraft:coal",
        "minecraft:iron_ingot",
        "minecraft:copper_ingot",
        "minecraft:gold_ingot",
        "minecraft:diamond",
        "minecraft:emerald",
        "minecraft:lapis_lazuli",
        "minecraft:redstone",
        "minecraft:netherite_scrap"
    },
    
    -- Fuel items
    fuel = {
        "minecraft:coal",
        "minecraft:charcoal",
        "minecraft:coal_block",
        "minecraft:lava_bucket",
        "minecraft:blaze_rod",
        "minecraft:stick",
        "minecraft:planks",
        "minecraft:log",
        "minecraft:wood"
    },
    
    -- Building materials
    building = {
        "minecraft:cobblestone",
        "minecraft:stone",
        "minecraft:deepslate",
        "minecraft:cobbled_deepslate",
        "minecraft:dirt",
        "minecraft:gravel",
        "minecraft:sand",
        "minecraft:netherrack",
        "minecraft:andesite",
        "minecraft:diorite",
        "minecraft:granite",
        "minecraft:tuff"
    },
    
    -- Valuable items (keep these)
    valuable = {
        "minecraft:diamond",
        "minecraft:emerald",
        "minecraft:ancient_debris",
        "minecraft:netherite_scrap",
        "minecraft:netherite_ingot",
        "minecraft:enchanted_book",
        "minecraft:golden_apple",
        "minecraft:enchanted_golden_apple",
        "minecraft:totem_of_undying",
        "minecraft:elytra",
        "minecraft:trident",
        "minecraft:heart_of_the_sea",
        "minecraft:nether_star"
    },
    
    -- Tools (never drop these)
    tool = {
        "minecraft:diamond_pickaxe",
        "minecraft:netherite_pickaxe",
        "minecraft:iron_pickaxe",
        "minecraft:stone_pickaxe",
        "minecraft:golden_pickaxe",
        "minecraft:wooden_pickaxe",
        "minecraft:diamond_shovel",
        "minecraft:netherite_shovel",
        "minecraft:iron_shovel",
        "minecraft:diamond_axe",
        "minecraft:netherite_axe",
        "minecraft:iron_axe"
    }
}

-- Helper function to check if item matches any pattern
local function matchesPattern(item_name, patterns)
    for _, pattern in ipairs(patterns) do
        if item_name == pattern then
            return true
        end
        -- Also check for wildcard patterns
        if pattern:find("*") then
            local regex_pattern = pattern:gsub("*", ".*")
            if item_name:match(regex_pattern) then
                return true
            end
        end
    end
    return false
end

-- Initialize the module
function Inventory.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.debug("Initializing Inventory module")
    
    -- Load custom item patterns from config
    local custom_patterns = Config.get("custom_item_patterns")
    if custom_patterns then
        for category, patterns in pairs(custom_patterns) do
            if ITEM_PATTERNS[category] then
                for _, pattern in ipairs(patterns) do
                    table.insert(ITEM_PATTERNS[category], pattern)
                end
            else
                ITEM_PATTERNS[category] = patterns
            end
        end
    end
    
    -- Initial inventory scan
    Inventory.scanInventory()
    
    -- Register event handler for inventory changes
    Core.on("turtle_inventory", function()
        Inventory.scanInventory()
    end)
    
    initialized = true
    Core.info("Inventory module initialized")
    Core.emit("inventory_initialized")
    
    return true
end

-- Scan and cache inventory contents
function Inventory.scanInventory()
    inventory_cache = {}
    local total_items = 0
    local total_space = 0
    
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot, true)
        if detail then
            inventory_cache[slot] = {
                name = detail.name,
                count = detail.count,
                damage = detail.damage,
                max_damage = detail.maxDamage,
                display_name = detail.displayName,
                tags = detail.tags or {},
                category = Inventory.classifyItem(detail.name)
            }
            total_items = total_items + detail.count
        else
            inventory_cache[slot] = nil
        end
        total_space = total_space + turtle.getItemSpace(slot)
    end
    
    last_scan_time = os.epoch("utc")
    
    -- Update state
    State.set("inventory_total_items", total_items)
    State.set("inventory_free_space", total_space)
    
    Core.emit("inventory_scanned", {
        total_items = total_items,
        free_space = total_space,
        slots_used = Inventory.getUsedSlots()
    })
    
    return inventory_cache
end

-- Get current inventory (with optional rescan)
function Inventory.getInventory(force_scan)
    if force_scan or (os.epoch("utc") - last_scan_time) > scan_interval then
        Inventory.scanInventory()
    end
    return inventory_cache
end

-- Classify an item by name
function Inventory.classifyItem(item_name)
    if not item_name then return "unknown" end
    
    -- Check each category in priority order
    if matchesPattern(item_name, ITEM_PATTERNS.tool) then
        return "tool"
    elseif matchesPattern(item_name, ITEM_PATTERNS.valuable) then
        return "valuable"
    elseif matchesPattern(item_name, ITEM_PATTERNS.ore) then
        return "ore"
    elseif matchesPattern(item_name, ITEM_PATTERNS.fuel) then
        return "fuel"
    elseif matchesPattern(item_name, ITEM_PATTERNS.building) then
        return "building"
    else
        return "junk"
    end
end

-- Get items by category
function Inventory.getItemsByCategory(category)
    local items = {}
    local inventory = Inventory.getInventory()
    
    for slot, item in pairs(inventory) do
        if item.category == category then
            items[slot] = item
        end
    end
    
    return items
end

-- Get total count of a specific item
function Inventory.getItemCount(item_name)
    local count = 0
    local inventory = Inventory.getInventory()
    
    for _, item in pairs(inventory) do
        if item.name == item_name then
            count = count + item.count
        end
    end
    
    return count
end

-- Find slot containing specific item
function Inventory.findItem(item_name)
    local inventory = Inventory.getInventory()
    
    for slot, item in pairs(inventory) do
        if item.name == item_name then
            return slot, item.count
        end
    end
    
    return nil
end

-- Find empty slot
function Inventory.findEmptySlot()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return slot
        end
    end
    return nil
end

-- Get used/free slot counts
function Inventory.getUsedSlots()
    local used = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            used = used + 1
        end
    end
    return used
end

function Inventory.getFreeSlots()
    return 16 - Inventory.getUsedSlots()
end

-- Check if inventory is full
function Inventory.isFull()
    return Inventory.getFreeSlots() == 0
end

-- Select slot with specific item
function Inventory.selectItem(item_name)
    local slot = Inventory.findItem(item_name)
    if slot then
        turtle.select(slot)
        return true, slot
    end
    return false, "Item not found"
end

-- Consume fuel from inventory
function Inventory.consumeFuel(target_level)
    if not target_level then
        target_level = turtle.getFuelLimit()
    end
    
    local current_fuel = turtle.getFuelLevel()
    if current_fuel == "unlimited" then
        return true, "Unlimited fuel"
    end
    
    if current_fuel >= target_level then
        return true, "Sufficient fuel"
    end
    
    Core.debug("Attempting to refuel from " .. current_fuel .. " to " .. target_level)
    
    -- Find and consume fuel items
    local fuel_items = Inventory.getItemsByCategory("fuel")
    local fuel_consumed = 0
    
    for slot, item in pairs(fuel_items) do
        turtle.select(slot)
        
        -- Calculate how much fuel we need
        local fuel_needed = target_level - turtle.getFuelLevel()
        if fuel_needed <= 0 then
            break
        end
        
        -- Try to refuel
        local consumed = 0
        while turtle.getFuelLevel() < target_level and turtle.getItemCount(slot) > 0 do
            if turtle.refuel(1) then
                consumed = consumed + 1
                fuel_consumed = fuel_consumed + 1
            else
                break
            end
        end
        
        Core.debug("Consumed " .. consumed .. " " .. item.name .. " from slot " .. slot)
    end
    
    local final_fuel = turtle.getFuelLevel()
    Core.emit("fuel_consumed", {
        consumed = fuel_consumed,
        fuel_level = final_fuel
    })
    
    if final_fuel >= target_level then
        return true, "Refueled to " .. final_fuel
    else
        return false, "Insufficient fuel items"
    end
end

-- Drop items to make space
function Inventory.makeSpace(slots_needed, protect_categories)
    slots_needed = slots_needed or 1
    protect_categories = protect_categories or {"tool", "valuable", "ore"}
    
    local slots_freed = 0
    local items_dropped = 0
    
    -- Create a protection lookup table
    local protected = {}
    for _, category in ipairs(protect_categories) do
        protected[category] = true
    end
    
    -- First pass: drop junk items
    local inventory = Inventory.getInventory(true)
    for slot, item in pairs(inventory) do
        if slots_freed >= slots_needed then
            break
        end
        
        if not protected[item.category] and item.category == "junk" then
            turtle.select(slot)
            if turtle.drop() then
                slots_freed = slots_freed + 1
                items_dropped = items_dropped + item.count
                Core.debug("Dropped " .. item.count .. " " .. item.name)
            end
        end
    end
    
    -- Second pass: drop building materials if needed
    if slots_freed < slots_needed then
        for slot, item in pairs(inventory) do
            if slots_freed >= slots_needed then
                break
            end
            
            if not protected[item.category] and item.category == "building" then
                turtle.select(slot)
                if turtle.drop() then
                    slots_freed = slots_freed + 1
                    items_dropped = items_dropped + item.count
                    Core.debug("Dropped " .. item.count .. " " .. item.name)
                end
            end
        end
    end
    
    Core.emit("items_dropped", {
        slots_freed = slots_freed,
        items_dropped = items_dropped
    })
    
    return slots_freed >= slots_needed, slots_freed
end

-- Compact inventory by combining stacks
function Inventory.compact()
    Core.debug("Compacting inventory")
    local moves = 0
    
    -- Scan current inventory
    Inventory.scanInventory()
    
    -- Find items that can be combined
    local item_slots = {}
    for slot, item in pairs(inventory_cache) do
        if not item_slots[item.name] then
            item_slots[item.name] = {}
        end
        table.insert(item_slots[item.name], {
            slot = slot,
            count = item.count,
            space = turtle.getItemSpace(slot)
        })
    end
    
    -- Combine stacks
    for item_name, slots in pairs(item_slots) do
        if #slots > 1 then
            -- Sort by count (fullest first)
            table.sort(slots, function(a, b) return a.count > b.count end)
            
            -- Try to combine into fuller slots
            for i = 1, #slots - 1 do
                local target = slots[i]
                if target.space > 0 then
                    for j = i + 1, #slots do
                        local source = slots[j]
                        if source.count > 0 then
                            turtle.select(source.slot)
                            if turtle.transferTo(target.slot, math.min(source.count, target.space)) then
                                moves = moves + 1
                                -- Update counts
                                local transferred = math.min(source.count, target.space)
                                source.count = source.count - transferred
                                target.space = target.space - transferred
                                
                                if target.space == 0 then
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Rescan after compacting
    Inventory.scanInventory()
    
    Core.debug("Compacted inventory with " .. moves .. " moves")
    Core.emit("inventory_compacted", {moves = moves})
    
    return true, moves
end

-- Sort inventory by category
function Inventory.sort()
    Core.debug("Sorting inventory")
    
    -- Define sort order
    local sort_order = {
        tool = 1,
        valuable = 2,
        ore = 3,
        fuel = 4,
        building = 5,
        junk = 6,
        unknown = 7
    }
    
    -- Get all items with their slots
    local items = {}
    local inventory = Inventory.getInventory(true)
    
    for slot, item in pairs(inventory) do
        table.insert(items, {
            slot = slot,
            item = item,
            sort_key = (sort_order[item.category] or 7) * 1000 + slot
        })
    end
    
    -- Sort items
    table.sort(items, function(a, b) return a.sort_key < b.sort_key end)
    
    -- Move items to temporary storage (slots 13-16)
    local temp_slots = {13, 14, 15, 16}
    local temp_used = {}
    
    for _, temp_slot in ipairs(temp_slots) do
        if turtle.getItemCount(temp_slot) > 0 then
            temp_used[temp_slot] = true
        end
    end
    
    -- Rearrange items
    local target_slot = 1
    for _, item_data in ipairs(items) do
        if item_data.slot ~= target_slot then
            turtle.select(item_data.slot)
            -- Find a temporary slot if target is occupied
            if turtle.getItemCount(target_slot) > 0 then
                for _, temp_slot in ipairs(temp_slots) do
                    if not temp_used[temp_slot] then
                        turtle.select(target_slot)
                        turtle.transferTo(temp_slot)
                        temp_used[temp_slot] = true
                        break
                    end
                end
            end
            -- Move item to target
            turtle.select(item_data.slot)
            turtle.transferTo(target_slot)
        end
        target_slot = target_slot + 1
    end
    
    -- Move any items from temporary storage back
    for temp_slot, _ in pairs(temp_used) do
        if turtle.getItemCount(temp_slot) > 0 then
            turtle.select(temp_slot)
            for slot = 1, 12 do
                if turtle.getItemCount(slot) == 0 then
                    turtle.transferTo(slot)
                    break
                end
            end
        end
    end
    
    -- Rescan after sorting
    Inventory.scanInventory()
    
    Core.emit("inventory_sorted")
    return true
end

-- Check for tools and their durability
function Inventory.checkTools()
    local tools = Inventory.getItemsByCategory("tool")
    local tool_status = {}
    
    for slot, tool in pairs(tools) do
        local health = nil
        if tool.damage and tool.max_damage and tool.max_damage > 0 then
            health = 1 - (tool.damage / tool.max_damage)
        end
        
        table.insert(tool_status, {
            slot = slot,
            name = tool.name,
            display_name = tool.display_name,
            health = health,
            damage = tool.damage,
            max_damage = tool.max_damage
        })
    end
    
    return tool_status
end

-- Drop all items except protected categories
function Inventory.dropAll(protect_categories)
    protect_categories = protect_categories or {"tool"}
    
    local protected = {}
    for _, category in ipairs(protect_categories) do
        protected[category] = true
    end
    
    local dropped = 0
    local inventory = Inventory.getInventory(true)
    
    for slot, item in pairs(inventory) do
        if not protected[item.category] then
            turtle.select(slot)
            if turtle.drop() then
                dropped = dropped + item.count
            end
        end
    end
    
    Core.emit("inventory_cleared", {items_dropped = dropped})
    return true, dropped
end

-- Store items in adjacent inventory
function Inventory.storeItems(direction, categories)
    direction = direction or "front"
    categories = categories or {"ore", "valuable", "building"}
    
    -- Verify there's an inventory
    local detect_func = direction == "up" and turtle.detectUp or
                       direction == "down" and turtle.detectDown or
                       turtle.detect
    
    if not detect_func() then
        return false, "No block detected"
    end
    
    -- Create category lookup
    local store_categories = {}
    for _, category in ipairs(categories) do
        store_categories[category] = true
    end
    
    local items_stored = 0
    local inventory = Inventory.getInventory(true)
    
    -- Select appropriate drop function
    local drop_func = direction == "up" and turtle.dropUp or
                     direction == "down" and turtle.dropDown or
                     turtle.drop
    
    for slot, item in pairs(inventory) do
        if store_categories[item.category] then
            turtle.select(slot)
            local dropped = drop_func()
            if dropped then
                items_stored = items_stored + item.count
                Core.debug("Stored " .. item.count .. " " .. item.name)
            end
        end
    end
    
    -- Rescan after storing
    Inventory.scanInventory()
    
    Core.emit("items_stored", {
        direction = direction,
        items_stored = items_stored
    })
    
    return items_stored > 0, items_stored
end

-- Get inventory summary
function Inventory.getSummary()
    local summary = {
        total_items = 0,
        free_slots = Inventory.getFreeSlots(),
        used_slots = Inventory.getUsedSlots(),
        categories = {},
        fuel_count = 0,
        has_tools = false
    }
    
    local inventory = Inventory.getInventory()
    
    for _, item in pairs(inventory) do
        summary.total_items = summary.total_items + item.count
        
        if not summary.categories[item.category] then
            summary.categories[item.category] = {
                count = 0,
                items = 0
            }
        end
        
        summary.categories[item.category].count = summary.categories[item.category].count + item.count
        summary.categories[item.category].items = summary.categories[item.category].items + 1
        
        if item.category == "fuel" then
            summary.fuel_count = summary.fuel_count + item.count
        elseif item.category == "tool" then
            summary.has_tools = true
        end
    end
    
    return summary
end

-- Shutdown function
function Inventory.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Inventory module")
    initialized = false
    
    return true
end

return Inventory