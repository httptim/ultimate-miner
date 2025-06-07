-- Storage Integration Module
-- Handles chest detection, item storage, and inventory management with external storage

local Storage = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Inventory = require("turtle.modules.inventory")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local known_storages = {}
local last_storage_scan = 0
local storage_stats = {
    items_stored = 0,
    trips_to_storage = 0,
    last_storage_time = 0
}

-- Storage types and their typical block names
local STORAGE_BLOCKS = {
    -- Vanilla chests
    ["minecraft:chest"] = {type = "chest", size = 27},
    ["minecraft:trapped_chest"] = {type = "chest", size = 27},
    ["minecraft:barrel"] = {type = "barrel", size = 27},
    ["minecraft:hopper"] = {type = "hopper", size = 5},
    ["minecraft:dropper"] = {type = "dropper", size = 9},
    ["minecraft:dispenser"] = {type = "dispenser", size = 9},
    
    -- Ender storage
    ["minecraft:ender_chest"] = {type = "ender_chest", size = 27, special = true},
    
    -- Shulker boxes (all colors)
    ["minecraft:shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:white_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:orange_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:magenta_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:light_blue_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:yellow_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:lime_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:pink_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:gray_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:light_gray_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:cyan_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:purple_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:blue_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:brown_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:green_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:red_shulker_box"] = {type = "shulker_box", size = 27, portable = true},
    ["minecraft:black_shulker_box"] = {type = "shulker_box", size = 27, portable = true}
}

-- Categories to store (configurable)
local DEFAULT_STORE_CATEGORIES = {"ore", "valuable", "building"}
local DEFAULT_KEEP_CATEGORIES = {"tool", "fuel"}

-- Initialize the module
function Storage.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.debug("Initializing Storage module")
    
    -- Load saved storage locations
    known_storages = State.get("known_storages", {})
    storage_stats = State.get("storage_stats", storage_stats)
    
    -- Register event handlers
    Core.on("inventory_full", function()
        if Config.get("auto_store", true) then
            Storage.handleFullInventory()
        end
    end)
    
    initialized = true
    Core.info("Storage module initialized")
    Core.emit("storage_initialized")
    
    return true
end

-- Check if a block is storage
local function isStorageBlock(block_data)
    if not block_data or not block_data.name then
        return false, nil
    end
    
    local storage_info = STORAGE_BLOCKS[block_data.name]
    if storage_info then
        return true, storage_info
    end
    
    -- Check for modded storage (common patterns)
    if block_data.name:find("chest") or 
       block_data.name:find("crate") or 
       block_data.name:find("barrel") or
       block_data.name:find("storage") then
        return true, {type = "modded", size = 27}
    end
    
    return false, nil
end

-- Detect storage in a direction
function Storage.detectStorage(direction)
    direction = direction or "forward"
    
    local inspect_func
    if direction == "up" then
        inspect_func = turtle.inspectUp
    elseif direction == "down" then
        inspect_func = turtle.inspectDown
    else
        inspect_func = turtle.inspect
    end
    
    local success, block_data = inspect_func()
    if not success then
        return false, "No block detected"
    end
    
    local is_storage, storage_info = isStorageBlock(block_data)
    if is_storage then
        return true, {
            name = block_data.name,
            direction = direction,
            info = storage_info
        }
    end
    
    return false, "Not a storage block"
end

-- Scan all directions for storage
function Storage.scanForStorage()
    local storages = {}
    local directions = {"forward", "up", "down"}
    
    -- Also check left and right by turning
    local original_facing = Navigation.getPosition().facing
    
    for _, dir in ipairs(directions) do
        local found, storage = Storage.detectStorage(dir)
        if found then
            table.insert(storages, storage)
            Core.debug("Found storage " .. dir .. ": " .. storage.name)
        end
    end
    
    -- Check left
    Navigation.turnLeft()
    local found, storage = Storage.detectStorage("forward")
    if found then
        storage.direction = "left"
        table.insert(storages, storage)
    end
    
    -- Check right
    Navigation.turnRight()
    Navigation.turnRight()
    found, storage = Storage.detectStorage("forward")
    if found then
        storage.direction = "right"
        table.insert(storages, storage)
    end
    
    -- Return to original facing
    Navigation.turnLeft()
    
    last_storage_scan = os.epoch("utc")
    
    return storages
end

-- Store items in a specific direction
function Storage.storeInDirection(direction, categories)
    categories = categories or DEFAULT_STORE_CATEGORIES
    
    -- Detect if there's storage
    local has_storage, storage_data = Storage.detectStorage(direction)
    if not has_storage then
        return false, "No storage detected " .. direction
    end
    
    Core.debug("Storing items in " .. storage_data.name .. " " .. direction)
    
    -- Get appropriate drop function
    local drop_func
    if direction == "up" then
        drop_func = turtle.dropUp
    elseif direction == "down" then
        drop_func = turtle.dropDown
    else
        drop_func = turtle.drop
    end
    
    -- Store items by category
    local items_stored = 0
    local slots_freed = 0
    
    for _, category in ipairs(categories) do
        local items = Inventory.getItemsByCategory(category)
        for slot, item in pairs(items) do
            turtle.select(slot)
            
            -- Try to store all items in this slot
            local before_count = turtle.getItemCount(slot)
            if drop_func() then
                local after_count = turtle.getItemCount(slot)
                local stored = before_count - after_count
                
                if stored > 0 then
                    items_stored = items_stored + stored
                    Core.debug("Stored " .. stored .. " " .. item.name)
                    
                    if after_count == 0 then
                        slots_freed = slots_freed + 1
                    end
                end
            else
                Core.debug("Storage full or incompatible for " .. item.name)
            end
        end
    end
    
    -- Update statistics
    if items_stored > 0 then
        storage_stats.items_stored = storage_stats.items_stored + items_stored
        storage_stats.last_storage_time = os.epoch("utc")
        State.set("storage_stats", storage_stats)
        
        Core.emit("items_stored", {
            count = items_stored,
            slots_freed = slots_freed,
            storage = storage_data.name,
            direction = direction
        })
    end
    
    -- Rescan inventory
    Inventory.scanInventory()
    
    return items_stored > 0, items_stored
end

-- Store items in any available storage
function Storage.storeItems(categories)
    categories = categories or DEFAULT_STORE_CATEGORIES
    
    -- Scan for available storage
    local storages = Storage.scanForStorage()
    if #storages == 0 then
        return false, "No storage found nearby"
    end
    
    local total_stored = 0
    
    -- Try each storage
    for _, storage in ipairs(storages) do
        -- Handle turning for left/right
        if storage.direction == "left" then
            Navigation.turnLeft()
            storage.direction = "forward"
        elseif storage.direction == "right" then
            Navigation.turnRight()
            storage.direction = "forward"
        end
        
        local success, count = Storage.storeInDirection(storage.direction, categories)
        if success then
            total_stored = total_stored + count
        end
        
        -- Turn back
        if storage.direction == "forward" and 
           (storage.direction == "left" or storage.direction == "right") then
            Navigation.turnRight()
        end
        
        -- Stop if inventory has enough space
        if Inventory.getFreeSlots() >= 8 then
            break
        end
    end
    
    return total_stored > 0, total_stored
end

-- Store all items except keep categories
function Storage.storeAll(keep_categories)
    keep_categories = keep_categories or DEFAULT_KEEP_CATEGORIES
    
    -- Build list of categories to store
    local all_categories = {"ore", "valuable", "fuel", "building", "junk", "unknown"}
    local store_categories = {}
    
    for _, category in ipairs(all_categories) do
        local should_keep = false
        for _, keep in ipairs(keep_categories) do
            if category == keep then
                should_keep = true
                break
            end
        end
        
        if not should_keep then
            table.insert(store_categories, category)
        end
    end
    
    return Storage.storeItems(store_categories)
end

-- Find and remember storage location
function Storage.markStorageLocation(name)
    name = name or "storage"
    
    local pos = Navigation.getPosition()
    local storage_pos = {
        x = pos.x,
        y = pos.y,
        z = pos.z,
        name = name,
        last_visit = os.epoch("utc")
    }
    
    -- Check if already known
    for i, storage in ipairs(known_storages) do
        if storage.x == pos.x and storage.y == pos.y and storage.z == pos.z then
            -- Update existing
            known_storages[i] = storage_pos
            State.set("known_storages", known_storages)
            return true, "Updated storage location"
        end
    end
    
    -- Add new
    table.insert(known_storages, storage_pos)
    State.set("known_storages", known_storages)
    
    Core.info("Marked storage location: " .. name)
    return true, "Marked new storage location"
end

-- Get nearest known storage
function Storage.getNearestStorage()
    if #known_storages == 0 then
        return nil
    end
    
    local pos = Navigation.getPosition()
    local nearest = nil
    local min_distance = math.huge
    
    for _, storage in ipairs(known_storages) do
        local distance = math.abs(pos.x - storage.x) + 
                        math.abs(pos.y - storage.y) + 
                        math.abs(pos.z - storage.z)
        
        if distance < min_distance then
            min_distance = distance
            nearest = storage
        end
    end
    
    return nearest, min_distance
end

-- Return to storage when inventory is full
function Storage.returnToStorage()
    local storage, distance = Storage.getNearestStorage()
    if not storage then
        -- Try to find home as storage
        local home = Navigation.getHome()
        if home then
            storage = {
                x = home.x,
                y = home.y,
                z = home.z,
                name = "home"
            }
        else
            return false, "No known storage locations"
        end
    end
    
    Core.info("Returning to storage at " .. storage.name)
    
    -- Save current position to return later
    local return_pos = Navigation.getPosition()
    State.set("storage_return_position", return_pos)
    
    -- Go to storage
    local success, err = Navigation.moveTo(storage)
    if not success then
        return false, "Failed to reach storage: " .. tostring(err)
    end
    
    -- Update trip counter
    storage_stats.trips_to_storage = storage_stats.trips_to_storage + 1
    State.set("storage_stats", storage_stats)
    
    -- Store items
    local stored_success, items_count = Storage.storeAll()
    
    Core.emit("storage_trip_complete", {
        storage = storage.name,
        items_stored = items_count or 0,
        success = stored_success
    })
    
    return stored_success, items_count
end

-- Return from storage to previous position
function Storage.returnFromStorage()
    local return_pos = State.get("storage_return_position")
    if not return_pos then
        return false, "No return position saved"
    end
    
    Core.info("Returning to work position")
    
    local success, err = Navigation.moveTo(return_pos)
    if success then
        State.set("storage_return_position", nil)
    end
    
    return success, err
end

-- Handle full inventory automatically
function Storage.handleFullInventory()
    Core.warn("Inventory full - initiating storage protocol")
    
    -- First try to store locally
    local success, count = Storage.storeItems()
    if success and Inventory.getFreeSlots() >= 4 then
        Core.info("Stored " .. count .. " items locally")
        return true
    end
    
    -- If still full, return to storage
    if Inventory.getFreeSlots() < 4 then
        Core.info("Local storage insufficient, returning to base")
        return Storage.returnToStorage()
    end
    
    return true
end

-- Check if turtle has a specific storage item (like ender chest)
function Storage.hasPortableStorage()
    local portable_storages = {
        "minecraft:ender_chest",
        "minecraft:shulker_box"
    }
    
    -- Check for any shulker box color
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            for _, storage_name in ipairs(portable_storages) do
                if item.name == storage_name or item.name:find("shulker_box") then
                    return true, slot, item.name
                end
            end
        end
    end
    
    return false
end

-- Place and use portable storage
function Storage.usePortableStorage(direction)
    direction = direction or "forward"
    
    local has_portable, slot, storage_name = Storage.hasPortableStorage()
    if not has_portable then
        return false, "No portable storage in inventory"
    end
    
    Core.debug("Using portable storage: " .. storage_name)
    
    -- Select the storage item
    turtle.select(slot)
    
    -- Place it
    local place_func
    if direction == "up" then
        place_func = turtle.placeUp
    elseif direction == "down" then
        place_func = turtle.placeDown
    else
        place_func = turtle.place
    end
    
    if not place_func() then
        return false, "Failed to place portable storage"
    end
    
    -- Store items
    local success, count = Storage.storeInDirection(direction)
    
    -- Break the storage to pick it back up
    local dig_func
    if direction == "up" then
        dig_func = turtle.digUp
    elseif direction == "down" then
        dig_func = turtle.digDown
    else
        dig_func = turtle.dig
    end
    
    dig_func()
    
    return success, count
end

-- Get storage statistics
function Storage.getStats()
    return {
        items_stored = storage_stats.items_stored,
        trips_to_storage = storage_stats.trips_to_storage,
        last_storage_time = storage_stats.last_storage_time,
        known_locations = #known_storages,
        time_since_storage = os.epoch("utc") - storage_stats.last_storage_time
    }
end

-- Clear known storage locations
function Storage.clearStorageLocations()
    known_storages = {}
    State.set("known_storages", known_storages)
    Core.info("Cleared all known storage locations")
    return true
end

-- List known storage locations
function Storage.listStorageLocations()
    return known_storages
end

-- Shutdown function
function Storage.shutdown()
    if not initialized then
        return true
    end
    
    Core.debug("Shutting down Storage module")
    initialized = false
    
    return true
end

return Storage