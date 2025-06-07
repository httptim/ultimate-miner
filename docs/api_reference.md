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
Navigation.locateGPS(timeout: number?, silent: boolean?) -> boolean, table (position)
Navigation.calibrateGPS() -> boolean, string
Navigation.recoverGPS() -> boolean, string
Navigation.setManualPosition(x: number, y: number, z: number, facing: string|number?) -> boolean, string

-- Pathfinding
Navigation.moveTo(target: table, options: table?) -> boolean, string
-- Options: {
--   use_pathfinding: boolean (use A* algorithm),
--   fuel_check: boolean (ensure enough fuel),
--   recalculate_on_block: boolean (recalculate path if blocked),
--   max_iterations: number (pathfinding iteration limit),
--   avoid: table (positions to avoid),
--   no_cache: boolean (don't use cached paths)
-- }

Navigation.moveToSimple(target: table) -> boolean, string
Navigation.pathTo(target: table, options: table?) -> table (path), string
-- Options: {
--   max_distance: number (maximum path distance),
--   max_iterations: number (algorithm iteration limit),
--   avoid: table (hash table of positions to avoid),
--   no_cache: boolean (don't use cached paths)
-- }

Navigation.estimateFuel(target: table) -> number

-- Emergency protocols
Navigation.emergencyStop() -> boolean
Navigation.activateEmergencyReturn(reason: string) -> boolean, table|string
Navigation.returnHomeEmergency() -> boolean
Navigation.checkEmergencyConditions() -> boolean, string?

-- Path history
Navigation.getPathHistory() -> table
Navigation.getPathHistoryStats() -> table
Navigation.clearPathHistory() -> nil
Navigation.backtrack(steps: number?) -> boolean
Navigation.getLastPosition() -> table?

-- Utilities
Navigation.face(direction: number) -> boolean
Navigation.getFacing() -> number (0=north, 1=east, 2=south, 3=west)
Navigation.getDistance(target: table) -> number
Navigation.isWithinBounds(pos: table?) -> boolean, string?
Navigation.clearPathCache() -> nil
Navigation.getStats() -> table
```

### Inventory Module (`turtle.modules.inventory`)

Manages turtle inventory and item handling.

```lua
-- Initialize inventory
Inventory.init() -> boolean, string

-- Inventory scanning
Inventory.scanInventory() -> table (inventory_cache)
Inventory.getInventory(force_scan: boolean?) -> table

-- Item classification
Inventory.classifyItem(item_name: string) -> string
-- Classifications: "ore", "fuel", "valuable", "tool", "building", "junk", "unknown"

-- Item management
Inventory.getItemsByCategory(category: string) -> table (slot -> item)
Inventory.getItemCount(item_name: string) -> number
Inventory.findItem(item_name: string) -> number?, number? (slot, count)
Inventory.findEmptySlot() -> number?
Inventory.selectItem(item_name: string) -> boolean, string

-- Inventory status
Inventory.getUsedSlots() -> number
Inventory.getFreeSlots() -> number
Inventory.isFull() -> boolean
Inventory.getSummary() -> table (summary)

-- Fuel management
Inventory.consumeFuel(target_level: number?) -> boolean, string

-- Space management
Inventory.makeSpace(slots_needed: number?, protect_categories: table?) -> boolean, number (slots_freed)
Inventory.compact() -> boolean, number (moves)
Inventory.sort() -> boolean

-- Tool management
Inventory.checkTools() -> table (tool_status)

-- Storage operations
Inventory.dropAll(protect_categories: table?) -> boolean, number (items_dropped)
Inventory.storeItems(direction: string?, categories: table?) -> boolean, number (items_stored)
-- Direction: "front", "up", "down"

-- Shutdown
Inventory.shutdown() -> boolean
```

### Mining Module (`turtle.modules.mining`)

Controls mining operations and pattern execution.

```lua
-- Initialize mining
Mining.init() -> boolean, string

-- Basic inspection
Mining.inspect(direction: string?) -> boolean, table (block_data)
-- Direction: "forward" (default), "up", "down"
-- Block data includes: name, is_ore, ore_type, is_protected, is_falling, is_valuable

Mining.detect(direction: string?) -> boolean
Mining.compare(direction: string?) -> boolean

-- Mining operations
Mining.dig(direction: string?) -> boolean, string
-- Handles falling blocks, protected blocks, and inventory management

Mining.digMove(direction: string?) -> boolean, string
-- Digs and moves in one operation

-- Vein mining
Mining.mineVein(max_blocks: number?) -> boolean, number (blocks_mined)
-- Default max_blocks: 64

Mining.mineVeinOptimized(ore_type: string, max_blocks: number?) -> boolean, table (vein_data)
-- Enhanced vein mining with 3D search and clustering

-- Area mining
Mining.mineAround() -> boolean, number (blocks_mined)
-- Mines all 6 adjacent blocks

Mining.mine3x3(length: number?) -> boolean, number (length_mined)
-- Creates a 3x3 tunnel

-- Pattern execution
Mining.executePattern(pattern_type: string, options: table) -> boolean
-- Pattern types: "strip", "branch", "spiral", "quarry", "tunnel_3x3", "adaptive"
-- Options vary by pattern

Mining.getPatterns() -> table
-- Returns available patterns with descriptions

-- Ore-specific mining
Mining.mineForOre(ore_type: string, options: table?) -> boolean
-- Mines at optimal Y level for specific ore
-- Options: {pattern: string?, length: number?, return_home: boolean?}

Mining.startAdaptiveMining(options: table) -> boolean
-- Adaptive mining that adjusts based on ore density
-- Options: {ore_types: table?, target_ore: string?, max_blocks: number?}

-- Recommendations
Mining.getRecommendations(target: table) -> table
-- Returns pattern recommendations based on target
-- Target: {ore_type: string?, area: boolean?, exploration: boolean?}

-- Ore detection
Mining.findOre(radius: number?) -> table (ore_locations)
-- Returns array of {position, direction, ore_type, name}

-- Utility functions
Mining.canMine(direction: string?) -> boolean, string
-- Checks if block can be safely mined

Mining.getStats() -> table (statistics)
-- Returns: blocks_mined, ores_found, ore_percentage, runtime_seconds, blocks_per_minute, by_type

Mining.resetStats() -> boolean

-- Shutdown
Mining.shutdown() -> boolean
```

### Patterns Module (`turtle.modules.patterns`)

Implements various mining patterns.

```lua
-- Initialize patterns
Patterns.init() -> boolean, string

-- Execute pattern
Patterns.execute(pattern_type: string, options: table) -> boolean
-- Pattern types: "strip", "branch", "spiral", "quarry", "tunnel_3x3", "adaptive"

-- Strip Mining
Patterns.stripMine(options: table) -> boolean
-- Options: {
--   length: number (50),
--   spacing: number (3),
--   strips: number (5),
--   torch_interval: number (8),
--   return_home: boolean (true)
-- }

-- Branch Mining
Patterns.branchMine(options: table) -> boolean
-- Options: {
--   main_length: number (100),
--   branch_length: number (20),
--   branch_spacing: number (5),
--   torch_interval: number (8),
--   return_home: boolean (true)
-- }

-- Spiral Mining
Patterns.spiralMine(options: table) -> boolean
-- Options: {
--   max_radius: number (32),
--   layers: number (1),
--   torch_interval: number (8),
--   return_home: boolean (true)
-- }

-- Quarry
Patterns.quarry(options: table) -> boolean
-- Options: {
--   width: number (16),
--   length: number (16),
--   depth: number? (nil = to bedrock),
--   return_home: boolean (true)
-- }

-- 3x3 Tunnel
Patterns.tunnel3x3(options: table) -> boolean
-- Options: {
--   length: number (50),
--   torch_interval: number (8),
--   support_interval: number (16),
--   return_home: boolean (true)
-- }

-- Adaptive Mining
Patterns.adaptiveMine(options: table) -> boolean
-- Options: {
--   target_ore: string?,
--   max_blocks: number (1000),
--   base_pattern: string ("branch"),
--   return_home: boolean (true)
-- }

-- Pattern management
Patterns.getAvailablePatterns() -> table
-- Returns array of {type, name, description}

Patterns.getStats() -> table
-- Returns current pattern statistics

Patterns.stop() -> boolean
-- Stops current pattern

Patterns.resume() -> boolean
-- Resumes interrupted pattern (not fully implemented)

-- Shutdown
Patterns.shutdown() -> boolean
```

### Optimization Module (`turtle.modules.optimization`)

Handles mining optimization and efficiency tracking.

```lua
-- Initialize optimization
Optimization.init() -> boolean, string

-- Ore vein following
Optimization.followOreVein(ore_type: string?, options: table?) -> boolean, table (vein_data)
-- Options: {
--   max_blocks: number (64),
--   search_radius: number (1),
--   prioritize_clusters: boolean (true)
-- }

-- Y-level optimization
Optimization.getOptimalYLevel(ore_type: string) -> number, table (ore_data)
-- Returns optimal Y and full ore data

Optimization.isYLevelOptimal(ore_type: string, current_y: number, tolerance: number?) -> boolean, string
-- Checks if current Y is optimal for ore

Optimization.calculateBestYLevel(ore_types: table) -> number
-- Calculates best Y for multiple ore types

-- Pattern efficiency
Optimization.trackPatternEfficiency(pattern_name: string, stats: table) -> table (efficiency)
-- Updates and returns efficiency metrics

Optimization.recommendPattern(target: table) -> table
-- Returns pattern recommendations
-- Target: {ore_type: string?, area: table?, exploration: boolean?}

-- Ore prediction
Optimization.predictOreLocations(current_pos: table, ore_type: string, radius: number?) -> table
-- Returns predicted ore locations with confidence scores

-- Dynamic adjustment
Optimization.adjustPattern(current_pattern: table, real_time_stats: table) -> table
-- Returns pattern adjustments based on real-time data

-- Statistics
Optimization.getStats() -> table
-- Returns comprehensive optimization statistics

Optimization.clearData() -> boolean
-- Clears all optimization data

-- Shutdown
Optimization.shutdown() -> boolean
```

### Safety Module (`turtle.modules.safety`)

Handles hazard detection and emergency protocols.

```lua
-- Initialize safety
Safety.init() -> boolean, string

-- Hazard detection
Safety.checkHazard(direction: string?) -> table (hazard_info)
-- Returns: {safe: boolean, hazard: string?, danger_level: number?, message: string?}

Safety.performSafetyCheck() -> boolean, table (hazards)
-- Comprehensive check of fuel, inventory, surroundings, and boundaries

-- Movement safety
Safety.isSafeToMove(direction: string?) -> boolean, string
-- Checks hazards, fuel, and boundaries before movement

-- Specific hazard handlers
Safety.handleLavaHazard(direction: string) -> boolean
Safety.handleWaterHazard(direction: string) -> boolean
Safety.handleCriticalFuel(fuel_level: number) -> boolean
Safety.handleFullInventory() -> boolean

-- Emergency protocols
Safety.emergencyStop(reason: string) -> boolean
-- Stops all operations and saves state

-- Environmental safety
Safety.ensureFloorBelow() -> boolean
-- Places a block below if none exists

Safety.checkVoidBelow(max_depth: number?) -> boolean, number (depth)
-- Checks for void/drop below turtle

Safety.checkHealth() -> boolean, string
-- Placeholder for future health monitoring

-- Falling block detection and support
Safety.detectFallingBlockAbove() -> boolean, string (block_name)
-- Detects if there's a falling block (sand, gravel, etc.) above

Safety.placeFallingBlockSupport() -> boolean, string
-- Places temporary support (torch or block) for falling blocks

Safety.handleFallingBlockHazard() -> boolean
-- Handles falling block hazard by backing away and waiting

-- Structural integrity and cave-in prevention
Safety.checkStructuralIntegrity(mining_area: table?) -> table
-- Returns: {score: number, safe: boolean, issues: table, needs_support: boolean}

Safety.placeSupportPillar() -> boolean, number (height)
-- Places a support pillar from floor to ceiling

Safety.planSupportPillars(area: table) -> table (pillar_positions)
-- Plans support pillar positions for large excavations

Safety.preMiningCheck(direction: string?) -> boolean, string
-- Comprehensive pre-mining safety check including falling blocks

-- Recovery systems
Safety.recoverLostPosition() -> boolean, table (position), table (methods)
-- Attempts to recover position using GPS, state, landmarks, or dead reckoning

Safety.recoverState() -> table (recovery_report)
-- Comprehensive state recovery after restart

Safety.reconnectNetwork() -> boolean, string|number
-- Attempts to reconnect to network after connection loss

Safety.findLandmarks() -> table? (position)
-- Searches for landmark blocks to determine position

Safety.reconstructFromHistory(history: table) -> table? (position)
-- Reconstructs position from movement history

-- Mob detection and combat (limited by CC:Tweaked)
Safety.detectMob() -> boolean, table (indicators)
-- Detects possible mob presence through spawners or movement blocking

Safety.combatProtocol() -> boolean, number (attacks_made)
-- Basic combat protocol using turtle.attack()

-- Configuration
Safety.setSafetyRadius(radius: number) -> boolean
-- Sets maximum distance from home

-- Statistics
Safety.getStats() -> table
-- Returns: hazards_detected, emergency_stops, close_calls, last_check, time_since_check

Safety.resetStats() -> boolean

-- Shutdown
Safety.shutdown() -> boolean
```

### Storage Module (`turtle.modules.storage`)

Manages interaction with storage containers.

```lua
-- Initialize storage
Storage.init() -> boolean, string

-- Container detection
Storage.detectStorage(direction: string?) -> boolean, table (storage_data)
-- Returns storage info: {name, direction, info: {type, size, special?, portable?}}

Storage.scanForStorage() -> table (storages)
-- Scans all directions including left/right

-- Item storage
Storage.storeInDirection(direction: string, categories: table?) -> boolean, number (items_stored)
-- Categories default: {"ore", "valuable", "building"}

Storage.storeItems(categories: table?) -> boolean, number (items_stored)
-- Stores in any available storage nearby

Storage.storeAll(keep_categories: table?) -> boolean, number (items_stored)
-- Stores everything except keep_categories (default: {"tool", "fuel"})

-- Storage locations
Storage.markStorageLocation(name: string?) -> boolean, string
-- Marks current position as storage location

Storage.getNearestStorage() -> table?, number (distance)
-- Returns nearest known storage and distance

Storage.listStorageLocations() -> table
Storage.clearStorageLocations() -> boolean

-- Automated storage
Storage.returnToStorage() -> boolean, number (items_stored)
-- Goes to nearest storage and deposits items

Storage.returnFromStorage() -> boolean, string
-- Returns to previous work position

Storage.handleFullInventory() -> boolean
-- Automatically handles full inventory situation

-- Portable storage
Storage.hasPortableStorage() -> boolean, number (slot), string (name)
-- Checks for ender chest or shulker box

Storage.usePortableStorage(direction: string?) -> boolean, number (items_stored)
-- Places, uses, and retrieves portable storage

-- Statistics
Storage.getStats() -> table
-- Returns: items_stored, trips_to_storage, last_storage_time, known_locations, time_since_storage

-- Shutdown
Storage.shutdown() -> boolean
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