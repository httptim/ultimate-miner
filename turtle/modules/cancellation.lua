-- Cancellation Module
-- Graceful operation cancellation with cleanup

local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Alerts = require("turtle.modules.alerts")

local Cancellation = {}

-- Cancellation state
local cancellation_data = {
    -- Active operations that can be cancelled
    operations = {},
    
    -- Cancellation requests
    requests = {},
    
    -- Cleanup handlers
    cleanup_handlers = {},
    
    -- Global cancellation flag
    global_cancel = false,
    
    -- Statistics
    stats = {
        operations_started = 0,
        operations_completed = 0,
        operations_cancelled = 0,
        cleanup_success = 0,
        cleanup_failed = 0
    }
}

-- Operation states
local OPERATION_STATE = {
    RUNNING = "running",
    CANCELLING = "cancelling",
    CANCELLED = "cancelled",
    COMPLETED = "completed",
    FAILED = "failed"
}

-- Initialize cancellation system
function Cancellation.init()
    Core.log("INFO", "Initializing cancellation system")
    
    -- Register global handlers
    Core.on("terminate", function()
        Cancellation.cancelAll("User termination")
    end)
    
    Core.on("emergency_stop", function()
        Cancellation.cancelAll("Emergency stop")
    end)
    
    -- Initialize last cleanup time
    cancellation_data.last_cleanup = os.epoch("utc")
    
    return true
end

-- Register a cancellable operation
function Cancellation.registerOperation(operation_id, operation_type, cleanup_handler)
    if cancellation_data.operations[operation_id] then
        Core.log("WARNING", "Operation already registered: " .. operation_id)
        return false
    end
    
    -- Create operation record
    local operation = {
        id = operation_id,
        type = operation_type,
        state = OPERATION_STATE.RUNNING,
        start_time = os.clock(),
        cleanup_handler = cleanup_handler,
        progress = 0,
        checkpoints = {},
        data = {}
    }
    
    cancellation_data.operations[operation_id] = operation
    cancellation_data.stats.operations_started = cancellation_data.stats.operations_started + 1
    
    Core.log("DEBUG", "Registered operation: " .. operation_id .. " (" .. operation_type .. ")")
    
    -- Start progress tracking
    Alerts.startProgress(operation_id, operation_type, 100)
    
    return true
end

-- Check if operation should be cancelled
function Cancellation.shouldCancel(operation_id)
    -- Check global cancellation
    if cancellation_data.global_cancel then
        return true, "Global cancellation active"
    end
    
    -- Check specific cancellation request
    local request = cancellation_data.requests[operation_id]
    if request then
        return true, request.reason
    end
    
    -- Check operation state
    local operation = cancellation_data.operations[operation_id]
    if operation and operation.state == OPERATION_STATE.CANCELLING then
        return true, "Operation is being cancelled"
    end
    
    return false
end

-- Create checkpoint for rollback
function Cancellation.checkpoint(operation_id, checkpoint_name, data)
    local operation = cancellation_data.operations[operation_id]
    if not operation then
        return false
    end
    
    -- Save checkpoint
    local checkpoint = {
        name = checkpoint_name,
        timestamp = os.clock(),
        data = data or {},
        position = turtle and {x = turtle.x, y = turtle.y, z = turtle.z} or nil
    }
    
    table.insert(operation.checkpoints, checkpoint)
    
    Core.log("DEBUG", "Checkpoint created: " .. checkpoint_name .. " for " .. operation_id)
    return true
end

-- Update operation progress
function Cancellation.updateProgress(operation_id, progress, message)
    local operation = cancellation_data.operations[operation_id]
    if not operation then
        return false
    end
    
    operation.progress = progress
    
    -- Update alert progress
    Alerts.updateProgress(operation_id, progress, message)
    
    -- Check for cancellation at progress intervals
    if progress % 10 == 0 then
        local should_cancel, reason = Cancellation.shouldCancel(operation_id)
        if should_cancel then
            Core.log("INFO", "Cancelling operation at " .. progress .. "%: " .. reason)
            return false, reason
        end
    end
    
    return true
end

-- Cancel specific operation
function Cancellation.cancelOperation(operation_id, reason)
    local operation = cancellation_data.operations[operation_id]
    if not operation then
        Core.log("WARNING", "Cannot cancel unknown operation: " .. operation_id)
        return false
    end
    
    if operation.state ~= OPERATION_STATE.RUNNING then
        Core.log("WARNING", "Cannot cancel operation in state: " .. operation.state)
        return false
    end
    
    -- Mark for cancellation
    cancellation_data.requests[operation_id] = {
        reason = reason or "User requested",
        timestamp = os.clock()
    }
    
    operation.state = OPERATION_STATE.CANCELLING
    
    Core.log("INFO", "Cancellation requested for " .. operation_id .. ": " .. reason)
    
    -- Send alert
    Alerts.create(Alerts.TYPES.WARNING, "Cancelling " .. operation.type .. ": " .. reason, 
                 Alerts.PRIORITY.HIGH, {operation_id = operation_id})
    
    -- Trigger cleanup immediately
    Cancellation.performCleanup(operation_id)
    
    return true
end

-- Cancel all operations
function Cancellation.cancelAll(reason)
    Core.log("WARNING", "Cancelling all operations: " .. reason)
    
    cancellation_data.global_cancel = true
    
    -- Cancel each active operation
    for operation_id, operation in pairs(cancellation_data.operations) do
        if operation.state == OPERATION_STATE.RUNNING then
            Cancellation.cancelOperation(operation_id, reason)
        end
    end
    
    -- Send critical alert
    Alerts.create(Alerts.TYPES.ERROR, "All operations cancelled: " .. reason, 
                 Alerts.PRIORITY.CRITICAL)
end

-- Perform cleanup for cancelled operation
function Cancellation.performCleanup(operation_id)
    local operation = cancellation_data.operations[operation_id]
    if not operation then
        return
    end
    
    Core.log("INFO", "Performing cleanup for " .. operation_id)
    
    local cleanup_success = true
    local cleanup_errors = {}
    
    -- Run custom cleanup handler if provided
    if operation.cleanup_handler then
        local success, err = pcall(operation.cleanup_handler, operation)
        if not success then
            cleanup_success = false
            table.insert(cleanup_errors, "Custom cleanup failed: " .. tostring(err))
        end
    end
    
    -- Default cleanup actions
    local default_success, default_err = Cancellation.performDefaultCleanup(operation)
    if not default_success then
        cleanup_success = false
        table.insert(cleanup_errors, default_err)
    end
    
    -- Update state
    if cleanup_success then
        operation.state = OPERATION_STATE.CANCELLED
        cancellation_data.stats.cleanup_success = cancellation_data.stats.cleanup_success + 1
        Core.log("INFO", "Cleanup completed for " .. operation_id)
        
        -- Complete progress as cancelled
        Alerts.completeProgress(operation_id, "Cancelled: " .. operation.type)
    else
        operation.state = OPERATION_STATE.FAILED
        cancellation_data.stats.cleanup_failed = cancellation_data.stats.cleanup_failed + 1
        Core.log("ERROR", "Cleanup failed for " .. operation_id .. ": " .. table.concat(cleanup_errors, ", "))
        
        -- Send error alert
        Alerts.createError("Cleanup failed", "Failed to cleanup " .. operation.type .. ": " .. cleanup_errors[1])
    end
    
    -- Update stats
    cancellation_data.stats.operations_cancelled = cancellation_data.stats.operations_cancelled + 1
    
    -- Clear cancellation request
    cancellation_data.requests[operation_id] = nil
end

-- Default cleanup actions
function Cancellation.performDefaultCleanup(operation)
    local errors = {}
    
    -- Save current state
    State.saveAll()
    
    -- Stop any active movement
    if turtle then
        -- Already stopped by cancellation check
    end
    
    -- Emit cancellation event
    Core.emit("operation_cancelled", operation.id, operation.type)
    
    return #errors == 0, table.concat(errors, ", ")
end

-- Complete operation successfully
function Cancellation.completeOperation(operation_id, result_data)
    local operation = cancellation_data.operations[operation_id]
    if not operation then
        return false
    end
    
    if operation.state ~= OPERATION_STATE.RUNNING then
        Core.log("WARNING", "Cannot complete operation in state: " .. operation.state)
        return false
    end
    
    -- Update state
    operation.state = OPERATION_STATE.COMPLETED
    operation.end_time = os.clock()
    operation.duration = operation.end_time - operation.start_time
    operation.result = result_data
    
    cancellation_data.stats.operations_completed = cancellation_data.stats.operations_completed + 1
    
    -- Complete progress
    Alerts.completeProgress(operation_id, "Completed: " .. operation.type)
    
    Core.log("INFO", "Operation completed: " .. operation_id .. " (took " .. 
             string.format("%.1f", operation.duration) .. "s)")
    
    -- Emit completion event
    Core.emit("operation_completed", operation_id, operation.type, result_data)
    
    return true
end

-- Cleanup completed operations
function Cancellation.cleanupCompleted()
    local cutoff_time = os.clock() - 300  -- Keep for 5 minutes
    local cleaned = 0
    
    for operation_id, operation in pairs(cancellation_data.operations) do
        if operation.state == OPERATION_STATE.COMPLETED or 
           operation.state == OPERATION_STATE.CANCELLED then
            
            local end_time = operation.end_time or operation.start_time
            if end_time < cutoff_time then
                cancellation_data.operations[operation_id] = nil
                cleaned = cleaned + 1
            end
        end
    end
    
    if cleaned > 0 then
        Core.log("DEBUG", "Cleaned up " .. cleaned .. " completed operations")
    end
end

-- Get operation status
function Cancellation.getOperationStatus(operation_id)
    local operation = cancellation_data.operations[operation_id]
    if not operation then
        return nil
    end
    
    return {
        id = operation.id,
        type = operation.type,
        state = operation.state,
        progress = operation.progress,
        start_time = operation.start_time,
        duration = operation.end_time and (operation.end_time - operation.start_time) or 
                  (os.clock() - operation.start_time),
        checkpoints = #operation.checkpoints
    }
end

-- Get all active operations
function Cancellation.getActiveOperations()
    local active = {}
    
    for operation_id, operation in pairs(cancellation_data.operations) do
        if operation.state == OPERATION_STATE.RUNNING or 
           operation.state == OPERATION_STATE.CANCELLING then
            table.insert(active, Cancellation.getOperationStatus(operation_id))
        end
    end
    
    return active
end

-- Get cancellation statistics
function Cancellation.getStatistics()
    return {
        stats = cancellation_data.stats,
        active_operations = #Cancellation.getActiveOperations(),
        global_cancel = cancellation_data.global_cancel
    }
end

-- Reset global cancellation
function Cancellation.resetGlobalCancel()
    cancellation_data.global_cancel = false
    Core.log("INFO", "Global cancellation reset")
end

-- Utility: Cancellable loop helper
function Cancellation.cancellableLoop(operation_id, iterations, callback)
    for i = 1, iterations do
        -- Check cancellation
        local should_cancel, reason = Cancellation.shouldCancel(operation_id)
        if should_cancel then
            return false, reason, i - 1
        end
        
        -- Run callback
        local success, result = pcall(callback, i)
        if not success then
            Core.log("ERROR", "Cancellable loop error: " .. tostring(result))
            return false, "Callback error: " .. tostring(result), i - 1
        end
        
        -- Update progress
        local progress = math.floor((i / iterations) * 100)
        Cancellation.updateProgress(operation_id, progress)
        
        -- Yield periodically
        if i % 50 == 0 then
            os.sleep(0)
        end
    end
    
    return true, nil, iterations
end

-- Utility: Cancellable wait
function Cancellation.cancellableWait(operation_id, duration)
    local start_time = os.clock()
    local check_interval = 0.5
    
    while os.clock() - start_time < duration do
        -- Check cancellation
        local should_cancel, reason = Cancellation.shouldCancel(operation_id)
        if should_cancel then
            return false, reason
        end
        
        -- Wait for interval or remaining time
        local remaining = duration - (os.clock() - start_time)
        local wait_time = math.min(check_interval, remaining)
        
        if wait_time > 0 then
            os.sleep(wait_time)
        end
    end
    
    return true
end

-- Tick function to be called periodically from main loop
function Cancellation.tick()
    local current_time = os.epoch("utc")
    
    -- Check if cleanup is due (every 5 seconds)
    if current_time - (cancellation_data.last_cleanup or 0) >= 5000 then
        Cancellation.cleanupCompleted()
        cancellation_data.last_cleanup = current_time
    end
end

-- Shutdown
function Cancellation.shutdown()
    Core.log("INFO", "Shutting down cancellation system")
    
    -- Cancel all active operations
    Cancellation.cancelAll("System shutdown")
    
    -- Save statistics
    State.save("cancellation_stats", cancellation_data.stats)
end

return Cancellation