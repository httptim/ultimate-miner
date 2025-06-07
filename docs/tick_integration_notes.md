# Tick Integration Notes

## Background

The following modules have been updated to use a tick-based approach instead of Core.schedule_repeating_task:

1. **monitoring.lua** - Uses `Monitoring.tick()` to check health and update metrics
2. **cancellation.lua** - Uses `Cancellation.tick()` to cleanup completed operations
3. **alerts.lua** - Uses `Alerts.tick()` to process alert queue

## Integration Required

The main turtle program (`turtle/main.lua`) needs to be updated to call these tick functions periodically. Since it's a menu-driven program, we need to add a background task system.

## Suggested Implementation

### Option 1: Parallel Execution
Use CC:Tweaked's `parallel` API to run the tick loop alongside the menu:

```lua
local function tickLoop()
    while running do
        -- Call tick functions
        if Monitoring.tick then Monitoring.tick() end
        if Cancellation.tick then Cancellation.tick() end
        if Alerts.tick then Alerts.tick() end
        
        -- Sleep for a short time (100ms)
        os.sleep(0.1)
    end
end

local function menuLoop()
    -- Existing main loop code
end

-- In main():
parallel.waitForAny(tickLoop, menuLoop)
```

### Option 2: Timer-Based Events
Use timers in the main event loop:

```lua
local tick_timer = os.startTimer(0.1)

while running do
    local event, param1, param2 = os.pullEvent()
    
    if event == "timer" and param1 == tick_timer then
        -- Call tick functions
        if Monitoring.tick then Monitoring.tick() end
        if Cancellation.tick then Cancellation.tick() end
        if Alerts.tick then Alerts.tick() end
        
        -- Schedule next tick
        tick_timer = os.startTimer(0.1)
    elseif event == "key" then
        -- Handle menu input
    end
end
```

## Tick Intervals

- **Monitoring**: Checks every 30 seconds for health, every 5 seconds for metrics
- **Cancellation**: Checks every 5 seconds for cleanup
- **Alerts**: Checks every 1 second for queue processing

The tick functions handle their own timing internally using `os.epoch("utc")` comparisons.

## Testing

After integration:
1. Verify monitoring updates fuel/position stats
2. Test alert queue processing (create test alerts)
3. Verify cancelled operations are cleaned up after 5 minutes