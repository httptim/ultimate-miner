-- Ultimate Miner - Area Mining Module
-- Handles area-based mining with boundaries, chunk awareness, and saturation detection

local Area = {}

-- Dependencies
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local Navigation = require("turtle.modules.navigation")
local Mining = require("turtle.modules.mining")
local Safety = require("turtle.modules.safety")

-- Constants
local STATE_KEY = "mining_areas"
local CHUNK_SIZE = 16
local MAX_AREA_SIZE = 256 -- Maximum blocks per side
local SATURATION_THRESHOLD = 0.95 -- 95% mined = saturated

-- Module state
local initialized = false
local assigned_area = nil
local area_progress = {}
local chunk_status = {} -- Track chunk mining status

-- Initialize module
function Area.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.log("INFO", "Initializing Area Mining module")
    
    -- Load saved state
    local saved_area = State.get("assigned_area")
    local saved_progress = State.get("area_progress", {})
    local saved_chunks = State.get("chunk_status", {})
    
    if saved_area then
        assigned_area = saved_area
        Core.log("INFO", "Resumed assigned area: " .. Area.formatArea(saved_area))
    end
    
    area_progress = saved_progress
    chunk_status = saved_chunks
    
    initialized = true
    Core.emit("area:initialized")
    return true
end

-- Define a mining area
function Area.defineArea(corner1, corner2, options)
    if not initialized then
        return false, "Module not initialized"
    end
    
    options = options or {}
    
    -- Ensure corners have all coordinates
    if not (corner1.x and corner1.z and corner2.x and corner2.z) then
        return false, "Corners must have x and z coordinates"
    end
    
    -- Calculate bounds
    local min_x = math.min(corner1.x, corner2.x)
    local max_x = math.max(corner1.x, corner2.x)
    local min_z = math.min(corner1.z, corner2.z)
    local max_z = math.max(corner1.z, corner2.z)
    
    -- Y levels (optional)
    local min_y = options.min_y or math.min(corner1.y or -64, corner2.y or -64)
    local max_y = options.max_y or math.max(corner1.y or 320, corner2.y or 320)
    
    -- Validate size
    local width = max_x - min_x + 1
    local length = max_z - min_z + 1
    
    if width > MAX_AREA_SIZE or length > MAX_AREA_SIZE then
        return false, string.format("Area too large (max %dx%d)", MAX_AREA_SIZE, MAX_AREA_SIZE)
    end
    
    local area = {
        id = options.id or os.epoch("utc"),
        name = options.name or "Area " .. os.date("%Y-%m-%d %H:%M"),
        bounds = {
            min_x = min_x,
            max_x = max_x,
            min_y = min_y,
            max_y = max_y,
            min_z = min_z,
            max_z = max_z
        },
        width = width,
        length = length,
        height = max_y - min_y + 1,
        total_blocks = width * length * (max_y - min_y + 1),
        pattern = options.pattern or "strip",
        priority = options.priority or 5,
        created = os.epoch("utc") / 1000,
        owner = options.owner or os.computerID()
    }
    
    -- Calculate chunks covered
    area.chunks = Area.getAreaChunks(area.bounds)
    
    Core.log("INFO", string.format("Defined area '%s': %dx%dx%d blocks, %d chunks", 
        area.name, width, length, area.height, #area.chunks))
    Core.emit("area:defined", area)
    
    return true, area
end

-- Get chunks covered by an area
function Area.getAreaChunks(bounds)
    local chunks = {}
    local chunk_min_x = math.floor(bounds.min_x / CHUNK_SIZE)
    local chunk_max_x = math.floor(bounds.max_x / CHUNK_SIZE)
    local chunk_min_z = math.floor(bounds.min_z / CHUNK_SIZE)
    local chunk_max_z = math.floor(bounds.max_z / CHUNK_SIZE)
    
    for cx = chunk_min_x, chunk_max_x do
        for cz = chunk_min_z, chunk_max_z do
            table.insert(chunks, {x = cx, z = cz})
        end
    end
    
    return chunks
end

-- Assign an area to this turtle
function Area.assignArea(area)
    if not initialized then
        return false, "Module not initialized"
    end
    
    if assigned_area then
        return false, "Already have an assigned area"
    end
    
    assigned_area = area
    area_progress[area.id] = area_progress[area.id] or {
        blocks_mined = 0,
        blocks_scanned = 0,
        ores_found = {},
        start_time = os.epoch("utc") / 1000,
        last_position = nil,
        sections_complete = {}
    }
    
    -- Initialize chunk status for this area
    for _, chunk in ipairs(area.chunks) do
        local chunk_key = string.format("%d,%d", chunk.x, chunk.z)
        chunk_status[chunk_key] = chunk_status[chunk_key] or {
            loaded = false,
            last_seen = 0,
            blocks_mined = 0,
            saturated = false
        }
    end
    
    -- Save state
    State.set("assigned_area", assigned_area)
    State.set("area_progress", area_progress)
    State.set("chunk_status", chunk_status)
    State.save()
    
    Core.log("INFO", "Assigned to area: " .. area.name)
    Core.emit("area:assigned", area)
    
    return true
end

-- Check if a position is within assigned area
function Area.isInBounds(pos)
    if not assigned_area then
        return true -- No area assigned, all positions valid
    end
    
    local bounds = assigned_area.bounds
    return pos.x >= bounds.min_x and pos.x <= bounds.max_x and
           pos.y >= bounds.min_y and pos.y <= bounds.max_y and
           pos.z >= bounds.min_z and pos.z <= bounds.max_z
end

-- Enforce area boundaries during movement
function Area.enforceBoundary(target_pos)
    if not assigned_area then
        return target_pos -- No enforcement needed
    end
    
    local bounds = assigned_area.bounds
    local enforced = {
        x = math.max(bounds.min_x, math.min(bounds.max_x, target_pos.x)),
        y = math.max(bounds.min_y, math.min(bounds.max_y, target_pos.y)),
        z = math.max(bounds.min_z, math.min(bounds.max_z, target_pos.z)),
        facing = target_pos.facing
    }
    
    if enforced.x ~= target_pos.x or enforced.y ~= target_pos.y or enforced.z ~= target_pos.z then
        Core.log("WARNING", "Position enforced to area boundary")
        Core.emit("area:boundary_enforced", target_pos, enforced)
    end
    
    return enforced
end

-- Mine the assigned area
function Area.mineAssignedArea()
    if not initialized then
        return false, "Module not initialized"
    end
    
    if not assigned_area then
        return false, "No area assigned"
    end
    
    local progress = area_progress[assigned_area.id]
    local start_pos = Navigation.getPosition()
    
    if not start_pos then
        return false, "Cannot determine position"
    end
    
    -- Check if we're in the area
    if not Area.isInBounds(start_pos) then
        Core.log("INFO", "Moving to assigned area")
        -- Move to area center at appropriate Y level
        local center = {
            x = math.floor((assigned_area.bounds.min_x + assigned_area.bounds.max_x) / 2),
            y = math.max(assigned_area.bounds.min_y, math.min(12, assigned_area.bounds.max_y)),
            z = math.floor((assigned_area.bounds.min_z + assigned_area.bounds.max_z) / 2)
        }
        
        local success, err = Navigation.moveTo(center, {
            use_pathfinding = true,
            fuel_check = true
        })
        
        if not success then
            return false, "Failed to reach area: " .. err
        end
    end
    
    -- Execute mining pattern within area
    Core.log("INFO", string.format("Mining area '%s' with pattern: %s", 
        assigned_area.name, assigned_area.pattern))
    
    local pattern_options = {
        area_bounds = assigned_area.bounds,
        resume_position = progress.last_position,
        on_block_mined = function(pos, block_data)
            -- Update progress
            progress.blocks_mined = progress.blocks_mined + 1
            progress.blocks_scanned = progress.blocks_scanned + 1
            progress.last_position = pos
            
            -- Track ores
            if block_data.is_ore then
                local ore_type = block_data.ore_type or "unknown"
                progress.ores_found[ore_type] = (progress.ores_found[ore_type] or 0) + 1
            end
            
            -- Update chunk status
            Area.updateChunkStatus(pos)
            
            -- Check saturation periodically
            if progress.blocks_mined % 100 == 0 then
                local saturation = Area.checkSaturation()
                if saturation >= SATURATION_THRESHOLD then
                    Core.log("INFO", string.format("Area saturated: %.1f%%", saturation * 100))
                    return "saturated"
                end
            end
            
            -- Emit progress event
            Core.emit("area:progress", {
                area = assigned_area,
                progress = progress,
                percentage = (progress.blocks_mined / assigned_area.total_blocks) * 100
            })
        end
    }
    
    -- Choose pattern based on area configuration
    local pattern_result
    if assigned_area.pattern == "strip" then
        pattern_options.length = assigned_area.length
        pattern_options.strips = math.ceil(assigned_area.width / 3)
        pattern_options.spacing = 3
        pattern_result = Mining.executePattern("strip", pattern_options)
    elseif assigned_area.pattern == "quarry" then
        pattern_options.width = assigned_area.width
        pattern_options.length = assigned_area.length
        pattern_options.depth = assigned_area.height
        pattern_result = Mining.executePattern("quarry", pattern_options)
    else
        -- Default to adaptive
        pattern_result = Mining.executePattern("adaptive", pattern_options)
    end
    
    -- Update final progress
    progress.end_time = os.epoch("utc") / 1000
    State.set("area_progress", area_progress)
    State.save()
    
    Core.log("INFO", string.format("Area mining complete. Mined %d blocks, found %d ore types", 
        progress.blocks_mined, Core.tableSize(progress.ores_found)))
    Core.emit("area:complete", assigned_area, progress)
    
    return true, progress
end

-- Update chunk status based on mining activity
function Area.updateChunkStatus(pos)
    local chunk_x = math.floor(pos.x / CHUNK_SIZE)
    local chunk_z = math.floor(pos.z / CHUNK_SIZE)
    local chunk_key = string.format("%d,%d", chunk_x, chunk_z)
    
    local status = chunk_status[chunk_key] or {}
    status.loaded = true
    status.last_seen = os.epoch("utc") / 1000
    status.blocks_mined = (status.blocks_mined or 0) + 1
    
    chunk_status[chunk_key] = status
    
    -- Periodic save
    if status.blocks_mined % 50 == 0 then
        State.set("chunk_status", chunk_status)
    end
end

-- Check area saturation
function Area.checkSaturation()
    if not assigned_area or not area_progress[assigned_area.id] then
        return 0
    end
    
    local progress = area_progress[assigned_area.id]
    local estimated_total = assigned_area.width * assigned_area.length * 10 -- Estimate 10 layers average
    
    return math.min(1, progress.blocks_mined / estimated_total)
end

-- Get area statistics
function Area.getAreaStats()
    if not assigned_area then
        return nil
    end
    
    local progress = area_progress[assigned_area.id] or {}
    local active_chunks = 0
    local saturated_chunks = 0
    
    for _, chunk in ipairs(assigned_area.chunks) do
        local chunk_key = string.format("%d,%d", chunk.x, chunk.z)
        local status = chunk_status[chunk_key]
        if status and status.blocks_mined > 0 then
            active_chunks = active_chunks + 1
            if status.saturated then
                saturated_chunks = saturated_chunks + 1
            end
        end
    end
    
    return {
        area = assigned_area,
        progress = {
            blocks_mined = progress.blocks_mined or 0,
            blocks_scanned = progress.blocks_scanned or 0,
            ores_found = progress.ores_found or {},
            time_mining = progress.end_time and (progress.end_time - progress.start_time) or 
                         ((os.epoch("utc") / 1000) - (progress.start_time or 0)),
            saturation = Area.checkSaturation(),
            active_chunks = active_chunks,
            saturated_chunks = saturated_chunks,
            total_chunks = #assigned_area.chunks
        }
    }
end

-- Release assigned area
function Area.releaseArea()
    if not assigned_area then
        return false, "No area assigned"
    end
    
    Core.log("INFO", "Released area: " .. assigned_area.name)
    Core.emit("area:released", assigned_area)
    
    assigned_area = nil
    State.delete("assigned_area")
    State.save()
    
    return true
end

-- Format area for display
function Area.formatArea(area)
    return string.format("%s (%d,%d,%d to %d,%d,%d)", 
        area.name or "Unnamed",
        area.bounds.min_x, area.bounds.min_y, area.bounds.min_z,
        area.bounds.max_x, area.bounds.max_y, area.bounds.max_z)
end

-- Check if chunk is likely loaded
function Area.isChunkLoaded(chunk_x, chunk_z)
    -- In vanilla, chunks are loaded in a radius around players
    -- We can't directly detect this, but we can track when we last saw blocks there
    local chunk_key = string.format("%d,%d", chunk_x, chunk_z)
    local status = chunk_status[chunk_key]
    
    if not status then
        return false, "unknown"
    end
    
    local time_since = (os.epoch("utc") / 1000) - (status.last_seen or 0)
    
    if time_since < 60 then
        return true, "recent" -- Seen in last minute
    elseif time_since < 300 then
        return true, "probable" -- Seen in last 5 minutes
    else
        return false, "stale" -- Not seen recently
    end
end

-- Get next unmined section
function Area.getNextSection()
    if not assigned_area then
        return nil
    end
    
    local progress = area_progress[assigned_area.id]
    local bounds = assigned_area.bounds
    
    -- Simple grid-based sectioning
    local section_size = 16 -- One chunk
    local sections_x = math.ceil(assigned_area.width / section_size)
    local sections_z = math.ceil(assigned_area.length / section_size)
    
    for sx = 0, sections_x - 1 do
        for sz = 0, sections_z - 1 do
            local section_key = string.format("%d,%d", sx, sz)
            if not progress.sections_complete[section_key] then
                -- Found incomplete section
                local section = {
                    key = section_key,
                    bounds = {
                        min_x = bounds.min_x + (sx * section_size),
                        max_x = math.min(bounds.min_x + ((sx + 1) * section_size) - 1, bounds.max_x),
                        min_y = bounds.min_y,
                        max_y = bounds.max_y,
                        min_z = bounds.min_z + (sz * section_size),
                        max_z = math.min(bounds.min_z + ((sz + 1) * section_size) - 1, bounds.max_z)
                    }
                }
                return section
            end
        end
    end
    
    return nil -- All sections complete
end

-- Mark section as complete
function Area.markSectionComplete(section_key)
    if not assigned_area then
        return false
    end
    
    local progress = area_progress[assigned_area.id]
    progress.sections_complete[section_key] = true
    
    State.set("area_progress", area_progress)
    State.save()
    
    return true
end

-- Shutdown module
function Area.shutdown()
    if not initialized then
        return true
    end
    
    Core.log("INFO", "Shutting down Area Mining module")
    
    -- Save current state
    State.set("area_progress", area_progress)
    State.set("chunk_status", chunk_status)
    State.save()
    
    initialized = false
    return true
end

return Area