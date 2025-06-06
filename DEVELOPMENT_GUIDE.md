# Ultimate Miner Development Guide

## Getting Started

This guide provides developers with the information needed to contribute to or extend the Ultimate Miner system.

## Development Environment Setup

### Prerequisites
1. Minecraft 1.21.1 with CC:Tweaked installed
2. A test world with:
   - Mining turtles with pickaxe attachments
   - Computers (regular and/or advanced)
   - Wireless modems or ender modems
   - Storage containers (chests, barrels)
   - Fuel sources (coal, charcoal, etc.)

### Recommended Setup
- Use a creative world for initial development
- Set up a GPS satellite array for testing GPS features
- Create test mining areas with various ore distributions
- Have both regular and advanced computers for UI testing

## Coding Standards

### Lua Style Guide

#### Naming Conventions
```lua
-- Variables and functions: snake_case
local my_variable = 42
local function calculate_distance(x1, y1, x2, y2)
    -- function body
end

-- Constants: UPPER_SNAKE_CASE
local MAX_FUEL_LEVEL = 20000
local DEFAULT_SAFETY_RADIUS = 100

-- Module tables: PascalCase
local NavigationModule = {}

-- Private functions: prefix with underscore
local function _internal_helper()
    -- private function
end
```

#### Module Structure
```lua
-- Module header
-- Navigation Module
-- Handles turtle movement, pathfinding, and GPS integration

local Navigation = {}

-- Module dependencies
local core = require("modules.core")
local config = require("modules.config")

-- Local variables
local current_position = {x = 0, y = 0, z = 0, facing = 0}
local gps_available = false

-- Private functions
local function _validate_position(pos)
    return pos and pos.x and pos.y and pos.z
end

-- Public API
function Navigation.init()
    -- Initialization code
end

function Navigation.moveTo(target)
    -- Public function implementation
end

-- Module export
return Navigation
```

### Error Handling

#### Standard Error Pattern
```lua
function someFunction(param)
    -- Validate inputs
    if not param then
        return false, "Parameter required"
    end
    
    -- Try operation
    local success, result = pcall(function()
        -- Potentially failing operation
        return riskyOperation(param)
    end)
    
    if not success then
        -- Log error
        core.log("ERROR", "Operation failed: " .. tostring(result))
        return false, result
    end
    
    return true, result
end
```

#### Error Categories
- **CRITICAL**: System cannot continue (no fuel, lost position)
- **ERROR**: Operation failed but system can recover
- **WARNING**: Unexpected but handled situation
- **INFO**: Normal operational information
- **DEBUG**: Detailed debugging information

## API Design Principles

### Module Interfaces

Each module should expose a clean, consistent API:

```lua
-- Good API design
local Mining = {}

-- Clear, action-oriented function names
function Mining.mineBlock(direction)
function Mining.detectOre(block_data)
function Mining.executePattern(pattern_name, options)

-- Consistent return values
-- Success: true, result
-- Failure: false, error_message
```

### Event System

Use a consistent event system for module communication:

```lua
-- Event emission
core.emit("mining.ore_found", {
    ore_type = "diamond_ore",
    position = current_position,
    quantity = 1
})

-- Event handling
core.on("mining.ore_found", function(data)
    -- Handle ore discovery
    updateStatistics(data)
end)
```

## Testing Guidelines

### Unit Testing Pattern
```lua
-- tests/turtle/test_navigation.lua
local Navigation = require("turtle.modules.navigation")

local function test_distance_calculation()
    local dist = Navigation.calculateDistance(
        {x=0, y=0, z=0},
        {x=3, y=4, z=0}
    )
    assert(dist == 5, "Distance calculation failed")
end

local function test_fuel_estimation()
    local fuel_needed = Navigation.estimateFuel(
        {x=0, y=0, z=0},
        {x=10, y=10, z=10}
    )
    assert(fuel_needed == 30, "Fuel estimation incorrect")
end

-- Run tests
test_distance_calculation()
test_fuel_estimation()
print("All navigation tests passed!")
```

### Integration Testing
```lua
-- Test module interactions
local function test_mining_with_navigation()
    -- Setup
    Navigation.init()
    Mining.init()
    
    -- Test integrated behavior
    local success = Mining.mineToPosition({x=10, y=64, z=10})
    assert(success, "Integrated mining failed")
end
```

## Performance Considerations

### Memory Management
```lua
-- Use circular buffers for history
local PathHistory = {}
PathHistory.max_size = 1000
PathHistory.buffer = {}
PathHistory.index = 1

function PathHistory:add(position)
    self.buffer[self.index] = position
    self.index = (self.index % self.max_size) + 1
end
```

### Network Optimization
```lua
-- Batch status updates
local status_buffer = {}
local last_update = os.clock()

function addStatusUpdate(data)
    table.insert(status_buffer, data)
    
    -- Send updates every 5 seconds
    if os.clock() - last_update > 5 then
        sendBatchUpdate(status_buffer)
        status_buffer = {}
        last_update = os.clock()
    end
end
```

## CC:Tweaked Specific Patterns

### Yielding for Long Operations
```lua
-- Yield periodically to prevent "too long without yielding"
function longOperation()
    for i = 1, 1000 do
        -- Do work
        processItem(i)
        
        -- Yield every 50 iterations
        if i % 50 == 0 then
            os.sleep(0)
        end
    end
end
```

### Event Loop Pattern
```lua
-- Main event loop
function main()
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" then
            handleTimer(p1)
        elseif event == "modem_message" then
            handleModemMessage(p1, p2, p3)
        elseif event == "key" then
            if p1 == keys.q then
                break  -- Exit
            end
        end
    end
end
```

### Peripheral Handling
```lua
-- Safe peripheral wrapping
function wrapPeripheral(side, type)
    if not peripheral.isPresent(side) then
        return nil, "No peripheral present"
    end
    
    if peripheral.getType(side) ~= type then
        return nil, "Wrong peripheral type"
    end
    
    return peripheral.wrap(side)
end
```

## Debugging Techniques

### Debug Logging
```lua
-- Conditional debug output
local DEBUG = config.get("debug_mode", false)

function debug(message)
    if DEBUG then
        print("[DEBUG] " .. os.date("%H:%M:%S") .. " " .. message)
    end
end
```

### State Inspection
```lua
-- Dump current state for debugging
function dumpState()
    print("=== Current State ===")
    print("Position:", textutils.serialize(current_position))
    print("Fuel:", turtle.getFuelLevel())
    print("Inventory:", getInventorySummary())
    print("===================")
end
```

## Common Patterns

### Resource Cleanup
```lua
-- Ensure cleanup on exit
local function cleanup()
    -- Save state
    state.save()
    
    -- Close network connections
    network.disconnect()
    
    -- Clear timers
    cancelAllTimers()
end

-- Set up cleanup
local function main()
    -- Main program logic
    local success, error = pcall(runProgram)
    
    -- Always cleanup
    cleanup()
    
    if not success then
        print("Error: " .. tostring(error))
    end
end
```

### Configuration Management
```lua
-- Flexible configuration with defaults
local defaults = {
    safety_radius = 100,
    fuel_reserve = 500,
    update_interval = 5,
    debug_mode = false
}

function loadConfig()
    local config = {}
    
    -- Load from file if exists
    if fs.exists("config.lua") then
        local file = fs.open("config.lua", "r")
        local data = file.readAll()
        file.close()
        config = textutils.unserialize(data) or {}
    end
    
    -- Apply defaults for missing values
    for key, value in pairs(defaults) do
        if config[key] == nil then
            config[key] = value
        end
    end
    
    return config
end
```

## Development Workflow

### 1. Plan Feature
- Review requirements in ROADMAP.md
- Check relevant CC:Tweaked documentation
- Design module interface
- Consider edge cases

### 2. Implement Feature
- Write core functionality
- Add error handling
- Implement safety checks
- Add debug logging

### 3. Test Feature
- Unit test individual functions
- Integration test with other modules
- Test edge cases
- Test in real Minecraft environment

### 4. Document Feature
- Add inline documentation
- Update API reference
- Add usage examples
- Update user manual

### 5. Optimize Feature
- Profile performance
- Optimize memory usage
- Reduce network traffic
- Improve user experience

## Troubleshooting Development Issues

### Common CC:Tweaked Issues

#### "Too long without yielding"
- Add `os.sleep(0)` in long loops
- Break up large operations
- Use coroutines for complex tasks

#### "Out of memory"
- Reduce history buffer sizes
- Clear unused variables
- Limit data retention
- Use weak tables where appropriate

#### "Cannot serialize type function"
- Remove functions from saved state
- Convert to data representations
- Use string identifiers instead

### Debugging Tools

#### In-Game Console
```lua
-- Interactive debugging console
function debugConsole()
    print("Debug Console (type 'exit' to quit)")
    while true do
        write("> ")
        local input = read()
        if input == "exit" then break end
        
        local func, err = load(input)
        if func then
            local ok, result = pcall(func)
            if ok then
                print(textutils.serialize(result))
            else
                print("Error: " .. result)
            end
        else
            print("Syntax error: " .. err)
        end
    end
end
```

## Contributing

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Implement your feature following these guidelines
4. Test thoroughly
5. Update documentation
6. Submit pull request with clear description

### Code Review Checklist
- [ ] Follows coding standards
- [ ] Includes error handling
- [ ] Has appropriate logging
- [ ] Includes tests
- [ ] Updates documentation
- [ ] Considers performance
- [ ] Handles edge cases
- [ ] Compatible with CC:Tweaked limits