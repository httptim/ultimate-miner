-- Ultimate Miner Control - Task Management Module
-- Handles resource targeting and area assignment for turtle fleet

local Tasks = {}

-- Dependencies
local Core = require("control.modules.core")
local Network = require("control.modules.network")
local Fleet = require("control.modules.fleet")
local Commands = require("control.modules.commands")

-- Constants
local TASK_TYPES = {
    RESOURCE_TARGET = "resource_target",
    AREA_MINING = "area_mining",
    SMART_MINING = "smart_mining",
    EXPLORATION = "exploration"
}

local TASK_PRIORITIES = {
    CRITICAL = 10,
    HIGH = 8,
    NORMAL = 5,
    LOW = 3,
    IDLE = 1
}

-- Module state
local initialized = false
local task_queue = {}
local active_tasks = {}
local completed_tasks = {}
local resource_targets = {}
local mining_areas = {}
local task_id_counter = 0

-- Initialize module
function Tasks.init()
    if initialized then
        return true, "Already initialized"
    end
    
    Core.log("INFO", "Initializing Task Management module")
    
    -- Register network handlers
    Network.registerHandler("task_progress", Tasks.handleTaskProgress)
    Network.registerHandler("task_complete", Tasks.handleTaskComplete)
    Network.registerHandler("task_failed", Tasks.handleTaskFailed)
    Network.registerHandler("area_saturated", Tasks.handleAreaSaturated)
    Network.registerHandler("resource_found", Tasks.handleResourceFound)
    
    -- Register commands
    Commands.register("assign_resource", {
        description = "Assign resource gathering task",
        parameters = {
            resource = "string (diamond|iron|gold|etc)",
            quantity = "number",
            priority = "number (1-10, optional)"
        },
        handler = Tasks.commandAssignResource
    })
    
    Commands.register("assign_area", {
        description = "Assign area mining task",
        parameters = {
            x1 = "number",
            z1 = "number", 
            x2 = "number",
            z2 = "number",
            y_min = "number (optional)",
            y_max = "number (optional)",
            pattern = "string (optional)"
        },
        handler = Tasks.commandAssignArea
    })
    
    Commands.register("start_smart_mining", {
        description = "Start smart mining session",
        parameters = {
            target_ores = "table (optional)",
            max_blocks = "number (optional)",
            timeout = "number (optional)"
        },
        handler = Tasks.commandStartSmartMining
    })
    
    initialized = true
    Core.emit("tasks:initialized")
    return true
end

-- Generate new task ID
local function generateTaskId()
    task_id_counter = task_id_counter + 1
    return string.format("task_%d_%d", os.computerID(), task_id_counter)
end

-- Create a resource targeting task
function Tasks.createResourceTask(resource_type, quantity, options)
    options = options or {}
    
    local task = {
        id = generateTaskId(),
        type = TASK_TYPES.RESOURCE_TARGET,
        resource = resource_type,
        quantity = quantity,
        priority = options.priority or TASK_PRIORITIES.NORMAL,
        created = os.epoch("utc") / 1000,
        status = "pending",
        assigned_to = nil,
        progress = {
            gathered = 0,
            percentage = 0,
            last_update = nil
        },
        options = {
            search_radius = options.search_radius or 128,
            timeout = options.timeout or 3600, -- 1 hour default
            pattern = options.pattern or "adaptive"
        }
    }
    
    -- Add to resource targets tracking
    if not resource_targets[resource_type] then
        resource_targets[resource_type] = {
            total_requested = 0,
            total_gathered = 0,
            active_tasks = {}
        }
    end
    resource_targets[resource_type].total_requested = 
        resource_targets[resource_type].total_requested + quantity
    resource_targets[resource_type].active_tasks[task.id] = task
    
    Core.log("INFO", string.format("Created resource task: %s x%d", resource_type, quantity))
    return task
end

-- Create an area mining task
function Tasks.createAreaTask(bounds, options)
    options = options or {}
    
    -- Calculate area details
    local width = math.abs(bounds.x2 - bounds.x1) + 1
    local length = math.abs(bounds.z2 - bounds.z1) + 1
    local area_size = width * length
    
    local task = {
        id = generateTaskId(),
        type = TASK_TYPES.AREA_MINING,
        area = {
            id = generateTaskId(),
            name = options.name or string.format("Area %dx%d", width, length),
            bounds = {
                min_x = math.min(bounds.x1, bounds.x2),
                max_x = math.max(bounds.x1, bounds.x2),
                min_y = bounds.y_min or -64,
                max_y = bounds.y_max or 320,
                min_z = math.min(bounds.z1, bounds.z2),
                max_z = math.max(bounds.z1, bounds.z2)
            },
            width = width,
            length = length,
            pattern = options.pattern or "strip"
        },
        priority = options.priority or TASK_PRIORITIES.NORMAL,
        created = os.epoch("utc") / 1000,
        status = "pending",
        assigned_to = nil,
        progress = {
            blocks_mined = 0,
            saturation = 0,
            last_update = nil
        }
    }
    
    -- Add to mining areas tracking
    mining_areas[task.area.id] = task.area
    
    Core.log("INFO", string.format("Created area task: %s (%d blocks)", 
        task.area.name, area_size))
    return task
end

-- Create a smart mining task
function Tasks.createSmartMiningTask(options)
    options = options or {}
    
    local task = {
        id = generateTaskId(),
        type = TASK_TYPES.SMART_MINING,
        priority = options.priority or TASK_PRIORITIES.NORMAL,
        created = os.epoch("utc") / 1000,
        status = "pending",
        assigned_to = nil,
        options = {
            target_ores = options.target_ores or {"diamond", "iron", "gold"},
            max_blocks = options.max_blocks or 10000,
            timeout = options.timeout or 7200 -- 2 hours default
        },
        progress = {
            blocks_mined = 0,
            ores_found = {},
            efficiency = 0,
            last_update = nil
        }
    }
    
    Core.log("INFO", "Created smart mining task")
    return task
end

-- Add task to queue
function Tasks.queueTask(task)
    -- Insert based on priority
    local inserted = false
    for i, existing in ipairs(task_queue) do
        if task.priority > existing.priority then
            table.insert(task_queue, i, task)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(task_queue, task)
    end
    
    Core.emit("tasks:queued", task)
    
    -- Try to assign immediately
    Tasks.assignPendingTasks()
    
    return true
end

-- Assign pending tasks to available turtles
function Tasks.assignPendingTasks()
    if #task_queue == 0 then
        return
    end
    
    -- Get available turtles
    local turtles = Fleet.getOnlineTurtles()
    
    for id, turtle in pairs(turtles) do
        if turtle.status == "idle" and not active_tasks[id] then
            -- Find suitable task
            local task = Tasks.findSuitableTask(turtle)
            
            if task then
                -- Assign task
                Tasks.assignTask(task, id)
            end
        end
    end
end

-- Find suitable task for turtle
function Tasks.findSuitableTask(turtle)
    for i, task in ipairs(task_queue) do
        -- Check if turtle can handle this task type
        local suitable = true
        
        -- Check capabilities (future: tool requirements, etc)
        if task.type == TASK_TYPES.AREA_MINING then
            -- Check if turtle is near the area
            if turtle.position then
                local area = task.area
                local distance = math.sqrt(
                    math.pow(turtle.position.x - (area.bounds.min_x + area.bounds.max_x) / 2, 2) +
                    math.pow(turtle.position.z - (area.bounds.min_z + area.bounds.max_z) / 2, 2)
                )
                -- Prefer nearby turtles for area tasks
                if distance > 200 then
                    suitable = false
                end
            end
        end
        
        if suitable then
            table.remove(task_queue, i)
            return task
        end
    end
    
    return nil
end

-- Assign task to turtle
function Tasks.assignTask(task, turtle_id)
    task.assigned_to = turtle_id
    task.status = "assigned"
    task.assigned_time = os.epoch("utc") / 1000
    
    active_tasks[turtle_id] = task
    
    -- Send task to turtle
    local command_data = {}
    
    if task.type == TASK_TYPES.RESOURCE_TARGET then
        Commands.execute(turtle_id, "add_resource_target", {
            resource = task.resource,
            quantity = task.quantity,
            options = task.options
        })
    elseif task.type == TASK_TYPES.AREA_MINING then
        Commands.execute(turtle_id, "assign_area", {
            area = task.area
        })
    elseif task.type == TASK_TYPES.SMART_MINING then
        Commands.execute(turtle_id, "start_smart_mining", {
            options = task.options
        })
    end
    
    -- Update fleet status
    Fleet.assignTask(turtle_id, task)
    
    Core.log("INFO", string.format("Assigned task %s to turtle %d", task.id, turtle_id))
    Core.emit("tasks:assigned", task, turtle_id)
end

-- Handle task progress update
function Tasks.handleTaskProgress(sender, data)
    local task = active_tasks[sender]
    if not task then
        return
    end
    
    -- Update progress based on task type
    if task.type == TASK_TYPES.RESOURCE_TARGET then
        task.progress.gathered = data.gathered or task.progress.gathered
        task.progress.percentage = (task.progress.gathered / task.quantity) * 100
        
        -- Update resource tracking
        local resource_data = resource_targets[task.resource]
        if resource_data then
            local previous = resource_data.active_tasks[task.id].progress.gathered or 0
            local delta = task.progress.gathered - previous
            resource_data.total_gathered = resource_data.total_gathered + delta
        end
    elseif task.type == TASK_TYPES.AREA_MINING then
        task.progress = data.progress or task.progress
    elseif task.type == TASK_TYPES.SMART_MINING then
        task.progress = data.progress or task.progress
    end
    
    task.progress.last_update = os.epoch("utc") / 1000
    
    Core.emit("tasks:progress", task, data)
end

-- Handle task completion
function Tasks.handleTaskComplete(sender, data)
    local task = active_tasks[sender]
    if not task then
        return
    end
    
    task.status = "completed"
    task.completed_time = os.epoch("utc") / 1000
    task.result = data.result
    
    -- Move to completed
    active_tasks[sender] = nil
    completed_tasks[task.id] = task
    
    -- Update tracking
    if task.type == TASK_TYPES.RESOURCE_TARGET then
        local resource_data = resource_targets[task.resource]
        if resource_data then
            resource_data.active_tasks[task.id] = nil
        end
    elseif task.type == TASK_TYPES.AREA_MINING then
        mining_areas[task.area.id].status = "completed"
    end
    
    Core.log("INFO", string.format("Task %s completed by turtle %d", task.id, sender))
    Core.emit("tasks:completed", task, data)
    
    -- Try to assign new task
    Tasks.assignPendingTasks()
end

-- Handle task failure
function Tasks.handleTaskFailed(sender, data)
    local task = active_tasks[sender]
    if not task then
        return
    end
    
    task.status = "failed"
    task.failed_time = os.epoch("utc") / 1000
    task.error = data.error
    
    -- Decide whether to retry
    if data.recoverable and (task.retry_count or 0) < 3 then
        task.retry_count = (task.retry_count or 0) + 1
        task.status = "pending"
        task.assigned_to = nil
        Tasks.queueTask(task)
        Core.log("WARNING", string.format("Task %s failed, retrying (%d/3)", 
            task.id, task.retry_count))
    else
        -- Move to completed (as failed)
        active_tasks[sender] = nil
        completed_tasks[task.id] = task
        Core.log("ERROR", string.format("Task %s failed permanently: %s", 
            task.id, data.error or "unknown"))
    end
    
    Core.emit("tasks:failed", task, data)
end

-- Handle area saturation
function Tasks.handleAreaSaturated(sender, data)
    Core.log("INFO", string.format("Turtle %d reports area saturated", sender))
    
    -- Find new area for turtle
    local available_areas = Tasks.getAvailableAreas()
    if #available_areas > 0 then
        -- Create new area task
        local area = available_areas[1]
        local task = Tasks.createAreaTask(area.bounds, {
            name = area.name,
            pattern = area.pattern
        })
        Tasks.queueTask(task)
    end
end

-- Handle resource found
function Tasks.handleResourceFound(sender, data)
    Core.log("INFO", string.format("Turtle %d found %s at (%d,%d,%d)", 
        sender, data.resource, data.position.x, data.position.y, data.position.z))
    
    -- Track resource locations (future: share with other turtles)
    Core.emit("tasks:resource_found", sender, data)
end

-- Get available areas (not assigned or completed)
function Tasks.getAvailableAreas()
    -- This would integrate with a larger area management system
    -- For now, return empty
    return {}
end

-- Command handlers
function Tasks.commandAssignResource(turtle_id, params)
    local task = Tasks.createResourceTask(
        params.resource,
        params.quantity,
        {priority = params.priority}
    )
    
    -- Assign directly if turtle specified, otherwise queue
    if Fleet.getTurtle(turtle_id) then
        Tasks.assignTask(task, turtle_id)
    else
        Tasks.queueTask(task)
    end
    
    return true
end

function Tasks.commandAssignArea(turtle_id, params)
    local task = Tasks.createAreaTask({
        x1 = params.x1,
        z1 = params.z1,
        x2 = params.x2,
        z2 = params.z2,
        y_min = params.y_min,
        y_max = params.y_max
    }, {pattern = params.pattern})
    
    if Fleet.getTurtle(turtle_id) then
        Tasks.assignTask(task, turtle_id)
    else
        Tasks.queueTask(task)
    end
    
    return true
end

function Tasks.commandStartSmartMining(turtle_id, params)
    local task = Tasks.createSmartMiningTask(params)
    
    if Fleet.getTurtle(turtle_id) then
        Tasks.assignTask(task, turtle_id)
    else
        Tasks.queueTask(task)
    end
    
    return true
end

-- Get task statistics
function Tasks.getStats()
    local stats = {
        queued = #task_queue,
        active = Core.tableSize(active_tasks),
        completed = Core.tableSize(completed_tasks),
        by_type = {},
        resource_totals = {},
        area_coverage = 0
    }
    
    -- Count by type
    for _, task in ipairs(task_queue) do
        stats.by_type[task.type] = (stats.by_type[task.type] or 0) + 1
    end
    for _, task in pairs(active_tasks) do
        stats.by_type[task.type] = (stats.by_type[task.type] or 0) + 1
    end
    
    -- Resource totals
    for resource, data in pairs(resource_targets) do
        stats.resource_totals[resource] = {
            requested = data.total_requested,
            gathered = data.total_gathered,
            percentage = (data.total_gathered / math.max(1, data.total_requested)) * 100
        }
    end
    
    -- Area coverage
    for _, area in pairs(mining_areas) do
        stats.area_coverage = stats.area_coverage + (area.width * area.length)
    end
    
    return stats
end

-- Get active tasks
function Tasks.getActiveTasks()
    local tasks = {}
    for turtle_id, task in pairs(active_tasks) do
        table.insert(tasks, {
            task = task,
            turtle_id = turtle_id,
            duration = (os.epoch("utc") / 1000) - (task.assigned_time or 0)
        })
    end
    return tasks
end

-- Get task queue
function Tasks.getQueue()
    return task_queue
end

-- Clear completed tasks older than specified time
function Tasks.cleanupCompleted(max_age)
    max_age = max_age or 3600 -- 1 hour default
    local current_time = os.epoch("utc") / 1000
    local cleaned = 0
    
    for id, task in pairs(completed_tasks) do
        local age = current_time - (task.completed_time or task.failed_time or 0)
        if age > max_age then
            completed_tasks[id] = nil
            cleaned = cleaned + 1
        end
    end
    
    Core.log("INFO", string.format("Cleaned up %d old completed tasks", cleaned))
    return cleaned
end

-- Shutdown module
function Tasks.shutdown()
    if not initialized then
        return true
    end
    
    Core.log("INFO", "Shutting down Task Management module")
    
    initialized = false
    return true
end

return Tasks