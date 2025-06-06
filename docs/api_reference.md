# Ultimate Miner API Reference

## Overview

This document defines the public APIs for all Ultimate Miner modules. Each module exposes a consistent interface for interaction with other components.

## Core Module APIs

### Core Module (`turtle.modules.core`)

The core module provides fundamental utilities used by all other modules.

```lua
-- Initialize the core module
core.init() -> boolean, string

-- Logging functions
core.log(level: string, message: string) -> nil
-- Levels: "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"

-- Event system
core.emit(event: string, data: table) -> nil
core.on(event: string, handler: function) -> number (handler_id)
core.off(event: string, handler_id: number) -> boolean

-- Vector operations
core.vector.add(v1: table, v2: table) -> table
core.vector.subtract(v1: table, v2: table) -> table
core.vector.distance(v1: table, v2: table) -> number
core.vector.equals(v1: table, v2: table) -> boolean

-- Utility functions
core.sleep(seconds: number) -> nil
core.tableContains(table: table, value: any) -> boolean
core.deepCopy(table: table) -> table
```

### Navigation Module (`turtle.modules.navigation`)

Handles all movement and positioning functionality.

```lua
-- Initialize navigation
Navigation.init(options: table?) -> boolean, string

-- Basic movement
Navigation.forward() -> boolean, string
Navigation.back() -> boolean, string
Navigation.up() -> boolean, string
Navigation.down() -> boolean, string
Navigation.turnLeft() -> boolean, string
Navigation.turnRight() -> boolean, string

-- Position management
Navigation.getPosition() -> table {x, y, z, facing}
Navigation.setPosition(pos: table) -> boolean
Navigation.setHome(pos: table?) -> boolean
Navigation.getHome() -> table

-- GPS integration
Navigation.locateGPS() -> boolean, table (position)
Navigation.calibrateGPS() -> boolean, string

-- Pathfinding
Navigation.moveTo(target: table, options: table?) -> boolean, string
-- Options: {
--   safe: boolean (avoid hazards),
--   fuel_check: boolean (ensure enough fuel),
--   timeout: number (max seconds)
-- }

Navigation.pathTo(target: table) -> table (path), string
Navigation.estimateFuel(target: table) -> number

-- Utilities
Navigation.face(direction: number) -> boolean
Navigation.getFacing() -> number (0=north, 1=east, 2=south, 3=west)
Navigation.getDistance(target: table) -> number
```

### Mining Module (`turtle.modules.mining`)

Controls mining operations and pattern execution.

```lua
-- Initialize mining
Mining.init(options: table?) -> boolean, string

-- Basic mining
Mining.dig() -> boolean, string
Mining.digUp() -> boolean, string
Mining.digDown() -> boolean, string

-- Ore detection
Mining.inspect() -> boolean, table (block_data)
Mining.inspectUp() -> boolean, table
Mining.inspectDown() -> boolean, table
Mining.isOre(block_data: table) -> boolean, string (ore_type)

-- Pattern execution
Mining.executePattern(pattern: string, options: table) -> boolean, string
-- Patterns: "strip", "branch", "spiral", "quarry", "tunnel3x3", "adaptive"
-- Options vary by pattern

-- Vein mining
Mining.mineVein(start_pos: table?, max_blocks: number?) -> number, table (positions)

-- Utilities
Mining.placeTorch() -> boolean
Mining.selectTool() -> boolean
Mining.canMine(block_data: table) -> boolean
```

### Inventory Module (`turtle.modules.inventory`)

Manages turtle inventory and item handling.

```lua
-- Initialize inventory
Inventory.init() -> boolean, string

-- Slot management
Inventory.getItemCount(slot: number?) -> number
Inventory.getItemDetail(slot: number) -> table?
Inventory.select(slot: number) -> boolean
Inventory.getSelectedSlot() -> number

-- Item operations
Inventory.transferTo(slot: number, quantity: number?) -> boolean
Inventory.drop(quantity: number?) -> boolean
Inventory.dropUp(quantity: number?) -> boolean
Inventory.dropDown(quantity: number?) -> boolean

-- Item classification
Inventory.classifyItem(item: table) -> string
-- Classifications: "ore", "fuel", "valuable", "tool", "torch", "junk"

-- Inventory management
Inventory.consolidate() -> boolean
Inventory.getFreeSlots() -> number
Inventory.isFull() -> boolean
Inventory.findItem(name: string) -> number? (slot)

-- Fuel management
Inventory.refuel(amount: number?) -> boolean, number (fuel_added)
Inventory.getFuelItems() -> table (slots)
Inventory.optimizeFuel() -> boolean
```

### Safety Module (`turtle.modules.safety`)

Handles hazard detection and emergency protocols.

```lua
-- Initialize safety
Safety.init(options: table?) -> boolean, string

-- Hazard detection
Safety.detectLava() -> boolean, string (direction)
Safety.detectWater() -> boolean, string
Safety.detectVoid() -> boolean, string
Safety.detectMob() -> boolean, string

-- Environmental safety
Safety.checkSurroundings() -> table (hazards)
Safety.isPositionSafe(pos: table) -> boolean, string
Safety.handleFallingBlock() -> boolean

-- Operational safety
Safety.checkFuel(required: number?) -> boolean, number (current)
Safety.hasEmergencyFuel() -> boolean
Safety.checkBounds(pos: table) -> boolean
Safety.detectClaim() -> boolean, table (claim_info)

-- Emergency protocols
Safety.emergencyReturn() -> boolean, string
Safety.emergencyStop() -> boolean
Safety.panicDrop() -> boolean
Safety.activateCombat() -> boolean
```

### Storage Module (`turtle.modules.storage`)

Manages interaction with storage containers.

```lua
-- Initialize storage
Storage.init() -> boolean, string

-- Container detection
Storage.detect() -> boolean, string (direction)
Storage.findStorage() -> table (directions)
Storage.isContainer(block_data: table) -> boolean

-- Item management
Storage.deposit(slots: table?) -> boolean, number (items_deposited)
Storage.depositAll() -> boolean, number
Storage.withdraw(item: string, count: number) -> boolean, number

-- Storage operations
Storage.optimizeStorage() -> boolean
Storage.getStorageInfo() -> table
Storage.hasSpace() -> boolean
```

### Network Module (`turtle.modules.network`)

Handles all network communication.

```lua
-- Initialize network
Network.init(protocol: string?) -> boolean, string

-- Connection management
Network.connect() -> boolean, string
Network.disconnect() -> boolean
Network.isConnected() -> boolean

-- Messaging
Network.send(recipient: number, message: table) -> boolean
Network.broadcast(message: table) -> boolean
Network.receive(timeout: number?) -> boolean, table (message)

-- Protocol handling
Network.setProtocol(protocol: string) -> boolean
Network.registerHandler(msg_type: string, handler: function) -> boolean

-- Status reporting
Network.sendStatus(status: table) -> boolean
Network.requestCommand() -> boolean, table (command)
```

### State Module (`turtle.modules.state`)

Manages persistent state storage.

```lua
-- Initialize state
State.init(filename: string?) -> boolean, string

-- State management
State.save() -> boolean, string
State.load() -> boolean, table (state)
State.reset() -> boolean

-- Data operations
State.set(key: string, value: any) -> boolean
State.get(key: string, default: any?) -> any
State.delete(key: string) -> boolean

-- Backup management
State.backup() -> boolean, string (backup_file)
State.restore(backup_file: string) -> boolean
State.validateState(state: table) -> boolean, string
```

### Config Module (`turtle.modules.config`)

Handles configuration management.

```lua
-- Initialize config
Config.init(filename: string?) -> boolean, string

-- Configuration access
Config.get(key: string, default: any?) -> any
Config.set(key: string, value: any) -> boolean
Config.save() -> boolean

-- Bulk operations
Config.load() -> boolean, table
Config.merge(new_config: table) -> boolean
Config.reset() -> boolean

-- Validation
Config.validate() -> boolean, table (errors)
Config.setSchema(schema: table) -> boolean
```

## Control Computer APIs

### Fleet Module (`control.modules.fleet`)

Manages multiple turtles.

```lua
-- Initialize fleet
Fleet.init() -> boolean, string

-- Turtle management
Fleet.registerTurtle(id: number, info: table) -> boolean
Fleet.unregisterTurtle(id: number) -> boolean
Fleet.getTurtle(id: number) -> table?
Fleet.getAllTurtles() -> table

-- Status monitoring
Fleet.updateStatus(id: number, status: table) -> boolean
Fleet.getStatus(id: number) -> table?
Fleet.getActiveCount() -> number

-- Command distribution
Fleet.sendCommand(id: number, command: table) -> boolean
Fleet.broadcastCommand(command: table) -> boolean
Fleet.assignTask(id: number, task: table) -> boolean
```

### UI Module (`control.modules.ui`)

Provides user interface functionality.

```lua
-- Initialize UI
UI.init() -> boolean, string

-- Display management
UI.clear() -> nil
UI.setCursorPos(x: number, y: number) -> nil
UI.write(text: string) -> nil
UI.setTextColor(color: number) -> nil
UI.setBackgroundColor(color: number) -> nil

-- Input handling
UI.readKey() -> number (key)
UI.readClick() -> number, number (x, y)
UI.prompt(message: string, options: table?) -> string

-- Screen management
UI.getSize() -> number, number (width, height)
UI.isColor() -> boolean
UI.pushScreen(screen: table) -> nil
UI.popScreen() -> nil
```

## Event Reference

### Turtle Events

```lua
-- Navigation events
"navigation.position_changed" -> {old: table, new: table}
"navigation.path_blocked" -> {position: table, reason: string}
"navigation.home_reached" -> {position: table}

-- Mining events
"mining.ore_found" -> {ore_type: string, position: table}
"mining.pattern_complete" -> {pattern: string, blocks_mined: number}
"mining.vein_complete" -> {ore_type: string, blocks: number}

-- Safety events
"safety.hazard_detected" -> {type: string, position: table}
"safety.fuel_critical" -> {level: number, required: number}
"safety.emergency_activated" -> {reason: string}

-- Network events
"network.connected" -> {id: number}
"network.disconnected" -> {reason: string}
"network.message_received" -> {sender: number, message: table}
```

### Control Computer Events

```lua
-- Fleet events
"fleet.turtle_joined" -> {id: number, info: table}
"fleet.turtle_left" -> {id: number, reason: string}
"fleet.status_update" -> {id: number, status: table}

-- Task events
"task.assigned" -> {turtle_id: number, task: table}
"task.completed" -> {turtle_id: number, task: table, result: table}
"task.failed" -> {turtle_id: number, task: table, error: string}
```

## Error Codes

Standard error codes used across all modules:

```lua
ERRORS = {
    -- General errors (1-99)
    UNKNOWN = 1,
    INVALID_PARAMETER = 2,
    NOT_INITIALIZED = 3,
    
    -- Movement errors (100-199)
    MOVEMENT_BLOCKED = 100,
    NO_FUEL = 101,
    POSITION_UNSAFE = 102,
    
    -- Mining errors (200-299)
    CANNOT_MINE = 200,
    TOOL_BROKEN = 201,
    INVENTORY_FULL = 202,
    
    -- Network errors (300-399)
    CONNECTION_FAILED = 300,
    TIMEOUT = 301,
    PROTOCOL_ERROR = 302,
    
    -- Storage errors (400-499)
    STORAGE_FULL = 400,
    NO_STORAGE_FOUND = 401,
    
    -- Safety errors (500-599)
    HAZARD_DETECTED = 500,
    EMERGENCY_STOP = 501,
    BOUNDARY_VIOLATION = 502
}
```

## Usage Examples

### Basic Mining Operation
```lua
local Navigation = require("modules.navigation")
local Mining = require("modules.mining")
local Safety = require("modules.safety")

-- Initialize modules
Navigation.init()
Mining.init()
Safety.init()

-- Mine to a specific position safely
local target = {x = 100, y = 12, z = 100}

-- Check safety and fuel
if Safety.checkFuel(Navigation.estimateFuel(target)) then
    -- Move to position
    local success, err = Navigation.moveTo(target, {safe = true})
    
    if success then
        -- Execute mining pattern
        Mining.executePattern("strip", {
            length = 50,
            spacing = 3,
            torch_interval = 8
        })
    else
        print("Movement failed: " .. err)
    end
else
    print("Insufficient fuel!")
end
```

### Fleet Command Example
```lua
local Fleet = require("modules.fleet")
local Tasks = require("modules.tasks")

-- Assign mining task to available turtle
local task = {
    type = "mine_area",
    area = {x1 = 0, z1 = 0, x2 = 64, z2 = 64, y = 12},
    pattern = "strip",
    return_when_full = true
}

-- Find available turtle
for id, turtle in pairs(Fleet.getAllTurtles()) do
    if turtle.status == "idle" then
        Fleet.assignTask(id, task)
        break
    end
end
```