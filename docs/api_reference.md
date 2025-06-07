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

Handles all network communication using rednet protocol.

```lua
-- Initialize network
Network.init(protocol: string?) -> boolean, string
-- Default protocol: "ULTIMATE_MINER_V2"

-- Connection management
Network.connect() -> boolean, string
-- Starts heartbeat and broadcasts presence

Network.disconnect() -> boolean
-- Stops heartbeat and notifies network

Network.isConnected() -> boolean
-- Checks connection status and timeout

-- Messaging
Network.send(recipient: number, message: table) -> boolean
-- Sends message to specific computer with protocol

Network.broadcast(message: table) -> boolean
-- Broadcasts message to all computers with protocol

Network.receive(timeout: number?) -> boolean, table (message)
-- Receives messages filtered by protocol
-- Returns: success, {sender: number, message: table}

-- Protocol handling
Network.registerHandler(msg_type: string, handler: function) -> boolean
-- Registers handler for specific message types
-- Handler signature: function(sender: number, data: table)

-- Control computer management
Network.setControlComputer(id: number) -> nil
-- Sets the control computer ID for targeted messages

Network.getControlComputer() -> number?
-- Returns current control computer ID

-- Status reporting
Network.sendStatus(status: table) -> boolean
-- Sends status to control computer or broadcasts
-- Auto-adds type, id, and timestamp

Network.requestCommand() -> boolean, table (command)
-- Requests command from control computer
-- Waits for response with 5-second timeout

-- Network discovery
Network.discover(service_type: string?, timeout: number?) -> table
-- Discovers network services
-- Default service_type: "control_computer", timeout: 2
-- Returns array of {id: number, info: table, distance: number?}

-- Modem management
Network.openModem() -> boolean, string
-- Finds and opens best available modem
-- Priority: ender > wireless > wired

-- Heartbeat management
Network.startHeartbeat() -> nil
-- Starts automatic heartbeat (5-10 second intervals)

Network.stopHeartbeat() -> nil
-- Stops automatic heartbeat

-- Recovery
Network.reconnect() -> boolean, string
-- Attempts to reconnect after failure

-- Statistics
Network.getStats() -> table
-- Returns: {
--   connected: boolean,
--   computer_id: number,
--   protocol: string,
--   modem_type: string ("ender", "wireless", "wired"),
--   modem_side: string,
--   control_computer: number?,
--   last_heartbeat: number?,
--   heartbeat_interval: number,
--   last_message_time: number?,
--   message_handlers: table (array of registered types)
-- }

-- Shutdown
Network.shutdown() -> boolean
-- Disconnects and closes modem
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

### Core Module (`control.modules.core`)

Provides device detection and core utilities for control computer.

```lua
-- Initialize core
Core.init() -> boolean, string

-- Device capabilities
Core.getCapabilities() -> table
-- Returns: {
--   is_computer: boolean,
--   is_advanced: boolean,
--   has_color: boolean,
--   screen_width: number,
--   screen_height: number,
--   has_mouse: boolean,
--   has_touch: boolean,
--   has_speaker: boolean,
--   modem_sides: table
-- }

-- Logging
Core.log(level: string, message: string) -> nil
-- Levels: "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"

-- Event system
Core.emit(event: string, ...) -> nil
Core.on(event: string, handler: function) -> number
Core.off(event: string, handler_id: number) -> boolean

-- Utilities
Core.sleep(seconds: number) -> nil
Core.tableContains(tbl: table, value: any) -> boolean
Core.deepCopy(tbl: table) -> table
Core.tableKeys(tbl: table) -> table
Core.formatDuration(seconds: number) -> string

-- Shutdown
Core.shutdown() -> boolean
```

### Network Module (`control.modules.network`)

Handles network communication for control computer.

```lua
-- Initialize network
Network.init() -> boolean, string

-- Messaging
Network.send(recipient: number, message: table) -> boolean
Network.broadcast(message: table) -> boolean
Network.sendCommand(turtle_id: number, command: string, data: table) -> boolean

-- Status requests
Network.requestStatus(turtle_id: number) -> boolean
Network.requestAllStatus() -> boolean

-- Emergency control
Network.emergencyStopAll(reason: string?) -> boolean

-- Message handling
Network.registerHandler(msg_type: string, handler: function) -> boolean
-- Handler signature: function(sender: number, message: table)

-- Statistics
Network.getStats() -> table
-- Returns: {
--   initialized: boolean,
--   computer_id: number,
--   protocol: string,
--   modem_side: string,
--   modem_type: string,
--   heartbeat_timeout: number,
--   handlers_registered: table
-- }

-- Shutdown
Network.shutdown() -> boolean
```

### Fleet Module (`control.modules.fleet`)

Manages turtle registration and fleet coordination.

```lua
-- Initialize fleet
Fleet.init() -> boolean, string

-- Turtle registration
Fleet.registerTurtle(id: number, info: table) -> boolean
Fleet.unregisterTurtle(id: number, reason: string?) -> boolean

-- Turtle data access
Fleet.getTurtle(id: number) -> table?
Fleet.getAllTurtles() -> table
Fleet.getOnlineTurtles() -> table
Fleet.getStatusCounts() -> table

-- Status updates
Fleet.updateHeartbeat(id: number, data: table) -> boolean
Fleet.updateStatus(id: number, status: table) -> boolean

-- Task management
Fleet.assignTask(turtle_id: number, task: table) -> boolean, string?
Fleet.handleTaskComplete(id: number, result: table) -> nil
Fleet.handleError(id: number, error_data: table) -> nil

-- Fleet commands
Fleet.broadcastCommand(command: string, data: table) -> number
Fleet.emergencyStopAll(reason: string?) -> boolean

-- Data persistence
Fleet.saveFleetData() -> boolean
Fleet.loadFleetData() -> boolean

-- Statistics
Fleet.getStats() -> table
-- Returns: {
--   counts: table,
--   total_blocks_mined: number,
--   total_fuel_used: number,
--   oldest_turtle: table?,
--   newest_turtle: table?
-- }

-- Shutdown
Fleet.shutdown() -> boolean
```

### Commands Module (`control.modules.commands`)

Command dispatcher for turtle control.

```lua
-- Initialize commands
Commands.init() -> boolean, string

-- Command registration
Commands.register(name: string, command_def: table) -> boolean
-- command_def: {
--   description: string,
--   parameters: table,
--   handler: function?,
--   requires_online: boolean?
-- }

-- Command execution
Commands.execute(turtle_id: number, command_name: string, parameters: table) -> boolean, string?
Commands.executeMultiple(turtle_ids: table, command_name: string, parameters: table) -> table
Commands.executeAll(command_name: string, parameters: table) -> table

-- Available commands
Commands.getAvailable() -> table
-- Returns array of {name, description, parameters}

-- Parameter validation
Commands.validateParameters(schema: table, params: table) -> string?

-- Default commands:
-- "move_to" - Move to coordinates
-- "return_home" - Return to home position
-- "mine_pattern" - Execute mining pattern
-- "mine_area" - Mine specific area
-- "mine_ore" - Mine for specific ore
-- "emergency_stop" - Emergency stop
-- "pause" - Pause operation
-- "resume" - Resume operation
-- "get_status" - Request status
-- "get_inventory" - Request inventory
-- "refuel" - Refuel from inventory
-- "deposit_items" - Deposit to storage
-- "update_config" - Update configuration

-- Shutdown
Commands.shutdown() -> boolean
```

### UI Module (`control.modules.ui`)

Adaptive user interface system.

```lua
-- Initialize UI
UI.init() -> boolean, string

-- Display properties
UI.getSize() -> number, number (width, height)
UI.isColor() -> boolean
UI.isAdvanced() -> boolean

-- Basic drawing
UI.clear() -> nil
UI.drawHeader(title: string, subtitle: string?) -> nil
UI.drawFooter(text: string) -> nil
UI.drawText(x: number, y: number, text: string, color: number?) -> nil
UI.drawCenteredText(y: number, text: string, color: number?) -> nil

-- UI components
UI.drawMenu(items: table, selected: number, start_y: number?) -> nil
UI.drawTable(headers: table, rows: table, start_y: number?, selected_row: number?) -> nil
UI.drawProgressBar(x: number, y: number, width: number, progress: number, max: number) -> nil
UI.drawStatus(x: number, y: number, status: string) -> nil
UI.drawBox(x: number, y: number, width: number, height: number, title: string?) -> nil

-- Screen management
UI.showScreen(screen: table) -> nil
UI.pushScreen(screen: table) -> nil
UI.popScreen() -> nil
UI.render() -> nil
UI.refresh() -> nil

-- Screen object format:
-- {
--   name: string,
--   render: function,
--   refresh: function?,
--   onKey: function(key)?,
--   onChar: function(char)?,
--   onMouseClick: function(button, x, y)?,
--   onMouseScroll: function(direction, x, y)?,
--   onEnter: function?,
--   onExit: function?
-- }

-- Auto refresh
UI.startRefresh(interval: number?) -> nil
UI.stopRefresh() -> nil

-- User interaction
UI.prompt(message: string, default: string?) -> string
UI.showMessage(message: string, color: number?, duration: number?) -> nil
UI.confirm(message: string) -> boolean

-- Color scheme
UI.colors = {
    background: number,
    text: number,
    header: number,
    header_text: number,
    selected: number,
    selected_text: number,
    success: number,
    warning: number,
    error: number,
    border: number
}

-- Shutdown
UI.shutdown() -> boolean
```

## Phase 8: Advanced Features APIs

### Resource Targeting Module (`turtle.modules.targeting`)

Handles specific ore targeting with quantity goals and progress tracking.

```lua
-- Initialize module
Targeting.init() -> boolean, string

-- Add resource target
Targeting.addTarget(resource_type: string, quantity: number, options: table?) -> boolean, number (target_id)
-- Options: {
--   priority: number (1-10, default 5),
--   search_radius: number (default 128),
--   timeout: number (seconds, default 3600),
--   pattern: string (default "adaptive")
-- }

-- Remove target
Targeting.removeTarget(target_id: number) -> boolean, string

-- Get all targets
Targeting.getTargets() -> table
-- Returns array of {id, resource, quantity, gathered, remaining, priority, status, progress_percent}

-- Get current active target
Targeting.getCurrentTarget() -> table?

-- Get target progress
Targeting.getProgress(target_id: number) -> table?
-- Returns: {target, gathered, remaining, blocks_mined, veins_found, search_time, efficiency, complete}

-- Process next target in queue
Targeting.processNext() -> boolean, table|string

-- Clear all targets
Targeting.clearTargets() -> boolean, string

-- Get resource information
Targeting.getResourceInfo(resource_type: string) -> table?
-- Returns: {name, blocks, optimal_y, y_range, value, special?}

-- Get available resources
Targeting.getAvailableResources() -> table
-- Returns sorted array of resource definitions

-- Estimate time for resource gathering
Targeting.estimateTime(resource_type: string, quantity: number) -> table?
-- Returns: {seconds, blocks, formatted}

-- Get statistics
Targeting.getStats() -> table
-- Returns: {active_targets, completed_targets, total_search_time, resources_gathered, current_target}

-- Shutdown
Targeting.shutdown() -> boolean
```

### Area Mining Module (`turtle.modules.area`)

Manages area-based mining with boundaries and chunk awareness.

```lua
-- Initialize module
Area.init() -> boolean, string

-- Define mining area
Area.defineArea(corner1: table, corner2: table, options: table?) -> boolean, table (area)
-- corner1/corner2: {x, z, y?} coordinates
-- Options: {
--   id: string?,
--   name: string?,
--   min_y: number?,
--   max_y: number?,
--   pattern: string (default "strip"),
--   priority: number (default 5),
--   owner: number?
-- }

-- Get chunks covered by area
Area.getAreaChunks(bounds: table) -> table (chunks)

-- Assign area to turtle
Area.assignArea(area: table) -> boolean, string

-- Check if position is in bounds
Area.isInBounds(pos: table) -> boolean

-- Enforce boundary on position
Area.enforceBoundary(target_pos: table) -> table (enforced_pos)

-- Mine assigned area
Area.mineAssignedArea() -> boolean, table (progress)

-- Update chunk status
Area.updateChunkStatus(pos: table) -> nil

-- Check area saturation
Area.checkSaturation() -> number (0-1)

-- Get area statistics
Area.getAreaStats() -> table?
-- Returns: {area, progress: {blocks_mined, ores_found, time_mining, saturation, chunks...}}

-- Release assigned area
Area.releaseArea() -> boolean, string

-- Format area for display
Area.formatArea(area: table) -> string

-- Check if chunk is loaded
Area.isChunkLoaded(chunk_x: number, chunk_z: number) -> boolean, string
-- Status: "recent", "probable", "stale", "unknown"

-- Get next unmined section
Area.getNextSection() -> table?

-- Mark section complete
Area.markSectionComplete(section_key: string) -> boolean

-- Shutdown
Area.shutdown() -> boolean
```

### Smart Mining Module (`turtle.modules.smart_mining`)

Intelligent mining with adaptive strategies and optimization.

```lua
-- Initialize module
SmartMining.init() -> boolean, string

-- Optimize Y level for target ores
SmartMining.optimizeYLevel(target_ores: table?) -> boolean, number (best_y)
-- target_ores: array of ore names (default: {"diamond", "iron", "gold"})

-- Handle resource scarcity
SmartMining.handleScarcity(ore_type: string?) -> boolean, table (strategies_applied)
-- Strategies: expand_radius, change_depth, switch_pattern, relocate, change_target

-- Get alternative mining depths
SmartMining.getAlternativeDepths(ore_type: string, current_y: number) -> table (y_levels)

-- Adapt mining pattern
SmartMining.adaptPattern() -> boolean, table? (strategy)
-- Returns: {pattern, options, reason}

-- Execute smart mining session
SmartMining.mine(options: table?) -> boolean, table (results)
-- Options: {
--   target_ores: table?,
--   max_blocks: number?,
--   timeout: number?
-- }
-- Results: {blocks_mined, ores_found, time_seconds, blocks_per_minute, final_strategy}

-- Update mining statistics
SmartMining.updateStats(pos: table, block_data: table) -> nil

-- Get recent statistics window
SmartMining.getRecentStats(window_size: number?) -> table
-- Returns: {blocks, ores, ore_rate}

-- Get efficiency report
SmartMining.getEfficiencyReport() -> table
-- Returns: {
--   total_blocks, total_ores, overall_rate,
--   by_ore_type, pattern_efficiency, best_y_levels,
--   scarcity_mode
-- }

-- Reset statistics
SmartMining.resetStats() -> boolean

-- Shutdown
SmartMining.shutdown() -> boolean
```

### Task Management Module (`control.modules.tasks`)

Handles task creation, assignment, and tracking for turtle fleet.

```lua
-- Initialize module
Tasks.init() -> boolean, string

-- Create resource targeting task
Tasks.createResourceTask(resource_type: string, quantity: number, options: table?) -> table (task)
-- Options: {priority: number?, search_radius: number?, timeout: number?, pattern: string?}

-- Create area mining task
Tasks.createAreaTask(bounds: table, options: table?) -> table (task)
-- bounds: {x1, z1, x2, z2, y_min?, y_max?}
-- Options: {name: string?, pattern: string?, priority: number?}

-- Create smart mining task
Tasks.createSmartMiningTask(options: table?) -> table (task)
-- Options: {target_ores: table?, max_blocks: number?, timeout: number?, priority: number?}

-- Queue task for assignment
Tasks.queueTask(task: table) -> boolean

-- Assign pending tasks to available turtles
Tasks.assignPendingTasks() -> nil

-- Find suitable task for turtle
Tasks.findSuitableTask(turtle: table) -> table?

-- Assign task to specific turtle
Tasks.assignTask(task: table, turtle_id: number) -> nil

-- Handle task progress update
Tasks.handleTaskProgress(sender: number, data: table) -> nil

-- Handle task completion
Tasks.handleTaskComplete(sender: number, data: table) -> nil

-- Handle task failure
Tasks.handleTaskFailed(sender: number, data: table) -> nil

-- Handle area saturation
Tasks.handleAreaSaturated(sender: number, data: table) -> nil

-- Handle resource found
Tasks.handleResourceFound(sender: number, data: table) -> nil

-- Get available areas
Tasks.getAvailableAreas() -> table

-- Get task statistics
Tasks.getStats() -> table
-- Returns: {queued, active, completed, by_type, resource_totals, area_coverage}

-- Get active tasks
Tasks.getActiveTasks() -> table
-- Returns array of {task, turtle_id, duration}

-- Get task queue
Tasks.getQueue() -> table

-- Clean up old completed tasks
Tasks.cleanupCompleted(max_age: number?) -> number (cleaned_count)

-- Shutdown
Tasks.shutdown() -> boolean
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
"network.resource_target_received" -> {sender: number, resource: string, quantity: number, options: table}
"network.area_assigned" -> {sender: number, area: table}
"network.smart_mining_start" -> {sender: number, options: table}

-- Resource targeting events
"targeting:initialized" -> nil
"targeting:target_added" -> {target: table}
"targeting:target_removed" -> {target: table}
"targeting:processing_target" -> {target: table}
"targeting:target_completed" -> {target: table, result: table}
"targeting:target_failed" -> {target: table, reason: string}
"targeting:targets_cleared" -> nil

-- Area mining events
"area:initialized" -> nil
"area:defined" -> {area: table}
"area:assigned" -> {area: table}
"area:boundary_enforced" -> {target_pos: table, enforced_pos: table}
"area:progress" -> {area: table, progress: table, percentage: number}
"area:complete" -> {area: table, progress: table}
"area:released" -> {area: table}

-- Smart mining events
"smart_mining:initialized" -> nil
"smart_mining:pattern_adapted" -> {strategy: table}
"smart_mining:scarcity_handled" -> {ore_type: string?, strategies: table, success: boolean}
"smart_mining:area_saturated" -> {area_stats: table}
"smart_mining:storage_needed" -> nil
```

### Control Computer Events

```lua
-- Fleet events
"fleet.turtle_joined" -> {id: number, info: table}
"fleet.turtle_left" -> {id: number, reason: string}
"fleet.status_update" -> {id: number, status: table}

-- Task events
"tasks:initialized" -> nil
"tasks:queued" -> {task: table}
"tasks:assigned" -> {task: table, turtle_id: number}
"tasks:progress" -> {task: table, data: table}
"tasks:completed" -> {task: table, data: table}
"tasks:failed" -> {task: table, data: table}
"tasks:resource_found" -> {sender: number, data: table}

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

### Resource Targeting Example (Phase 8)
```lua
local Targeting = require("turtle.modules.targeting")
local SmartMining = require("turtle.modules.smart_mining")

-- Initialize modules
Targeting.init()
SmartMining.init()

-- Add high-priority diamond target
Targeting.addTarget("diamond", 64, {
    priority = 9,
    search_radius = 256,
    pattern = "adaptive"
})

-- Add secondary targets
Targeting.addTarget("iron", 256, {priority = 5})
Targeting.addTarget("gold", 128, {priority = 6})

-- Process targets with smart mining
while Targeting.getCurrentTarget() do
    local success, result = Targeting.processNext()
    if success then
        print("Target completed: " .. textutils.serialize(result))
    end
end
```

### Area Mining Example (Phase 8)
```lua
local Area = require("turtle.modules.area")
local Network = require("turtle.modules.network")

-- Initialize modules
Area.init()

-- Define mining area
local success, area = Area.defineArea(
    {x = 100, z = 100},
    {x = 164, z = 164},
    {
        name = "North Quarry",
        min_y = -64,
        max_y = 16,
        pattern = "quarry"
    }
)

-- Assign and mine area
if success then
    Area.assignArea(area)
    local result = Area.mineAssignedArea()
    
    -- Report completion
    Network.sendAreaSaturated(Area.getAreaStats())
end
```

### Smart Mining with Task Management (Phase 8)
```lua
-- Control Computer Side
local Tasks = require("control.modules.tasks")
local Fleet = require("control.modules.fleet")

-- Create smart mining task for diamonds
local task = Tasks.createSmartMiningTask({
    target_ores = {"diamond", "emerald"},
    max_blocks = 10000,
    timeout = 7200,
    priority = 10
})

-- Queue for assignment
Tasks.queueTask(task)

-- Monitor progress
local function monitorTasks()
    while true do
        local stats = Tasks.getStats()
        print(string.format("Tasks: %d queued, %d active, %d completed",
            stats.queued, stats.active, stats.completed))
        
        -- Check resource totals
        for resource, data in pairs(stats.resource_totals) do
            print(string.format("%s: %d/%d (%.1f%%)",
                resource, data.gathered, data.requested, data.percentage))
        end
        
        os.sleep(10)
    end
end

parallel.waitForAny(monitorTasks)
```

## Phase 9: Production Features APIs

### Monitoring Module (`turtle.modules.monitoring`)

Advanced monitoring and analytics for production environments.

```lua
-- Initialize module
Monitoring.init() -> boolean, string

-- Health monitoring
Monitoring.performHealthCheck() -> boolean, table (issues)
-- Issues: array of {type, severity, message, solution}
-- Severity: "critical", "warning"

Monitoring.checkMovementHealth() -> boolean
-- Tests movement capability in all directions

Monitoring.detectGhostState() -> boolean
-- Detects if turtle is in ghost state (unresponsive)

Monitoring.attemptGhostRecovery() -> nil
-- Attempts to recover from ghost state

-- Performance tracking
Monitoring.startOperation(operation_type: string) -> nil
-- operation_type: "mine", "move", "turn", "dig", etc.

Monitoring.completeOperation(operation_type: string, success: boolean, data: table?) -> nil
-- Records operation completion with optional data

Monitoring.updateMetrics() -> nil
-- Updates real-time performance metrics

Monitoring.getRecentOperations(seconds: number) -> table
-- Returns operations within last N seconds

-- Resource analytics
Monitoring.recordResourceDiscovery(resource_type: string, count: number, position: table?) -> nil
-- Records ore discovery for analytics

Monitoring.updateHotspots(resource_type: string, position: table) -> nil
-- Updates hotspot detection system

-- Error tracking
Monitoring.recordError(error_type: string, error_msg: string) -> nil

-- Reports and data access
Monitoring.getPerformanceReport() -> table
-- Returns: {
--   totals: {blocks_mined, blocks_moved, items_collected, fuel_consumed, errors_encountered, time_mining, time_moving, time_idle},
--   current: {blocks_per_minute, fuel_efficiency, success_rate},
--   uptime: number
-- }

Monitoring.getResourceAnalytics() -> table
-- Returns: {
--   discoveries: {[resource]: {total, average_vein_size, locations_found, discovery_rate}},
--   ore_density: {[y_level]: {[resource]: count}},
--   hotspots: array of {center, resources, discovered, last_updated}
-- }

Monitoring.getHealthStatus() -> string, table (issues)
-- Returns: "healthy" or "unhealthy", array of issues

Monitoring.isGhost() -> boolean

Monitoring.getMetrics() -> table
-- Returns current real-time metrics

Monitoring.getHistory() -> table
-- Returns historical session data

-- Session management
Monitoring.createSessionSummary() -> table
-- Creates and stores session summary

Monitoring.save() -> nil
-- Saves monitoring data to disk

-- Shutdown
Monitoring.shutdown() -> nil
```

### Integrity Module (`turtle.modules.integrity`)

Triple backup system with checksum validation and atomic writes.

```lua
-- Initialize module
Integrity.init() -> boolean, string

-- Atomic write with checksum
Integrity.atomicWrite(filepath: string, data: any) -> boolean, string?
-- Writes data atomically with checksum validation and triple backups

-- Read with validation
Integrity.read(filepath: string) -> boolean, any|string
-- Reads and validates file with checksum, falls back to backups if corrupted

-- Read and validate single file
Integrity.readAndValidate(filepath: string) -> boolean, any|string, table?
-- Returns: success, data, package (with version, checksum, timestamp)

-- Version migration
Integrity.migrateData() -> nil
-- Automatically migrates old data formats to current version

Integrity.migrateDataStructure(data: table, from_version: string?) -> table
-- Migrates specific data structure

-- Corruption recovery
Integrity.recoverCorrupted(filepath: string) -> boolean, any
-- Attempts to recover corrupted file from backups or partial data

Integrity.attemptPartialRecovery(content: string) -> table?
-- Tries to extract valid data from corrupted content

-- Default data
Integrity.getDefaultData(filepath: string) -> table
-- Returns appropriate default data based on filename

-- Verification
Integrity.verifyAll() -> boolean, table (results)
-- Verifies all state files
-- Results: {[filename]: {valid, version, checksum}}

-- Backup management
Integrity.getBackupStatus(filepath: string) -> table
-- Returns: {main: boolean, backups: array of {exists, size}}

Integrity.cleanup() -> nil
-- Cleans up old backups and temporary files

-- Constants
Integrity.VERSION -> string (current version)
```

### Alerts Module (`turtle.modules.alerts`)

Progress notifications, error reporting with solutions, and priority-based alerts.

```lua
-- Initialize module
Alerts.init() -> boolean, string

-- Create alert
Alerts.create(alert_type: string, message: string, priority: number?, data: table?) -> string (alert_id)
-- alert_type: Alerts.TYPES.ERROR/WARNING/PROGRESS/SUCCESS/INFO
-- priority: Alerts.PRIORITY.CRITICAL/HIGH/MEDIUM/LOW/INFO (1-5)

-- Create error with solutions
Alerts.createError(error_type: string, error_msg: string) -> nil
-- Automatically provides solutions for known errors

-- Progress notifications
Alerts.startProgress(operation_id: string, operation_name: string, total: number?) -> string
-- Starts progress tracking for operation

Alerts.updateProgress(operation_id: string, current: number, message: string?) -> nil
-- Updates progress with optional message

Alerts.completeProgress(operation_id: string, message: string?) -> nil
-- Marks operation as complete

-- Alert processing
Alerts.processQueue() -> nil
-- Processes pending alerts (called automatically)

Alerts.processAlert(alert: table) -> nil
-- Processes individual alert

-- Display functions
Alerts.displayLocal(alert: table) -> nil
-- Shows alert on local display

Alerts.displaySolutions(solutions: table) -> nil
-- Shows error solutions

Alerts.sendNetworkAlert(alert: table) -> nil
-- Sends alert over network

Alerts.playAlertSound(priority: number) -> nil
-- Plays sound if speaker available

-- Data access
Alerts.getActiveProgress() -> table
-- Returns array of active progress operations

Alerts.getHistory(count: number?, filter_type: string?, min_priority: number?) -> table
-- Returns filtered alert history

-- Configuration
Alerts.configure(settings: table) -> nil
-- Settings: {enabled, min_priority, network_alerts, local_display, alert_sound}

Alerts.clear() -> nil
-- Clears alert queue

-- Utilities
Alerts.getPriorityName(priority: number) -> string

-- Constants
Alerts.PRIORITY = {CRITICAL = 1, HIGH = 2, MEDIUM = 3, LOW = 4, INFO = 5}
Alerts.TYPES = {ERROR = "error", WARNING = "warning", PROGRESS = "progress", SUCCESS = "success", INFO = "info"}
```

### Cancellation Module (`turtle.modules.cancellation`)

Graceful operation cancellation with cleanup.

```lua
-- Initialize module
Cancellation.init() -> boolean, string

-- Register cancellable operation
Cancellation.registerOperation(operation_id: string, operation_type: string, cleanup_handler: function?) -> boolean
-- cleanup_handler signature: function(operation: table) -> nil

-- Check cancellation
Cancellation.shouldCancel(operation_id: string) -> boolean, string?
-- Returns: should_cancel, reason

-- Create checkpoint
Cancellation.checkpoint(operation_id: string, checkpoint_name: string, data: table?) -> boolean
-- Saves checkpoint for potential rollback

-- Update progress
Cancellation.updateProgress(operation_id: string, progress: number, message: string?) -> boolean, string?
-- Returns false with reason if should cancel

-- Cancel operations
Cancellation.cancelOperation(operation_id: string, reason: string?) -> boolean

Cancellation.cancelAll(reason: string) -> nil
-- Cancels all active operations

-- Cleanup
Cancellation.performCleanup(operation_id: string) -> nil
-- Executes cleanup handlers

Cancellation.performDefaultCleanup(operation: table) -> boolean, string
-- Default cleanup actions

-- Complete operation
Cancellation.completeOperation(operation_id: string, result_data: table?) -> boolean
-- Marks operation as successfully completed

-- Management
Cancellation.cleanupCompleted() -> nil
-- Removes old completed operations

-- Status
Cancellation.getOperationStatus(operation_id: string) -> table?
-- Returns: {id, type, state, progress, start_time, duration, checkpoints}

Cancellation.getActiveOperations() -> table
-- Returns array of active operations

Cancellation.getStatistics() -> table
-- Returns: {stats: {...}, active_operations, global_cancel}

-- Control
Cancellation.resetGlobalCancel() -> nil

-- Utility helpers
Cancellation.cancellableLoop(operation_id: string, iterations: number, callback: function) -> boolean, string?, number
-- Returns: success, cancel_reason, completed_iterations
-- callback signature: function(iteration: number) -> nil

Cancellation.cancellableWait(operation_id: string, duration: number) -> boolean, string?
-- Waits with cancellation checking

-- Constants
Cancellation.OPERATION_STATE = {
    RUNNING = "running",
    CANCELLING = "cancelling", 
    CANCELLED = "cancelled",
    COMPLETED = "completed",
    FAILED = "failed"
}

-- Shutdown
Cancellation.shutdown() -> nil
```

### Diagnostics Module (`turtle.modules.diagnostics`)

Comprehensive diagnostics for troubleshooting and analysis.

```lua
-- Initialize module
Diagnostics.init() -> boolean, string

-- Run diagnostics
Diagnostics.runDiagnostics(category: string?) -> table (report)
-- category: TEST_CATEGORIES.SYSTEM/MOVEMENT/INVENTORY/NETWORK/STORAGE/SAFETY/PERFORMANCE/DATA
-- If no category, runs all tests

-- Test counting
Diagnostics.countTests(category: string?) -> number

-- Get tests for category
Diagnostics.getTestsForCategory(category: string) -> table
-- Returns array of {name, func}

-- Individual test execution
Diagnostics.runTest(test: table) -> table
-- Returns: {name, status, message, details, duration, timestamp}
-- status: "passed", "failed", "warning"

-- Category tests available:
-- SYSTEM: Turtle API, Fuel System, Computer Info, Peripheral Detection
-- MOVEMENT: Movement Capability, Position Tracking, GPS Signal, Pathfinding
-- INVENTORY: Inventory Space, Item Detection, Tool Slot, Fuel Items
-- NETWORK: Modem Presence, Network Connection, Control Response, Message Handling
-- STORAGE: Storage Detection, Storage Access, Home Position
-- SAFETY: Hazard Detection, Emergency Protocols, Safety Bounds
-- PERFORMANCE: Memory Usage, Operation Speed, Mining Efficiency
-- DATA: State Files, Data Integrity, Backup System

-- Report generation
Diagnostics.generateReport() -> table
-- Returns: {
--   timestamp, duration, summary: {passed, failed, warnings},
--   categories: {[category]: {passed, failed, warnings, tests}},
--   recommendations: array of strings
-- }

-- Category identification
Diagnostics.getCategoryForTest(test_name: string) -> string

-- Recommendations
Diagnostics.generateRecommendations(report: table) -> table (recommendations)

-- Data access
Diagnostics.getLastResults() -> table
-- Returns last diagnostic run results

-- Export
Diagnostics.exportResults(filename: string?) -> boolean, string
-- Exports results to file

-- Constants
Diagnostics.TEST_CATEGORIES = {
    SYSTEM = "system",
    MOVEMENT = "movement", 
    INVENTORY = "inventory",
    NETWORK = "network",
    STORAGE = "storage",
    SAFETY = "safety",
    PERFORMANCE = "performance",
    DATA = "data"
}
```

### Updated State Module

The State module has been updated to use the Integrity module for data protection.

```lua
-- Now uses component-based storage with integrity protection
State.init() -> boolean, string
-- Initializes with integrity system

State.save(component_name: string?, data: table?) -> boolean, string
-- Saves specific component or all components with atomic writes

State.load() -> boolean, table
-- Loads all components with checksum validation

State.verify() -> boolean, table
-- Verifies all state files using integrity system

State.restore() -> boolean
-- Attempts to restore from backups if corrupted

-- Component access
State.get(key: string, default: any?) -> any
-- Supports component prefixes: "position.x", "mining.blocks_mined"

State.set(key: string, value: any) -> boolean
-- Automatically determines component and saves atomically
```

## Phase 9 Events

### Production Feature Events

```lua
-- Monitoring events
"health_status" -> {healthy: boolean, issues: table}
"operation_start" -> {operation_type: string}
"operation_complete" -> {operation_type: string, success: boolean, data: table}
"resource_discovered" -> {resource_type: string, count: number, position: table}
"resource_analytics_updated" -> {resource_type: string, count: number, position: table}
"ghost_recovery_attempted" -> nil

-- Alert events
"alert" -> {alert_type: string, message: string, priority: number, data: table}
"progress_update" -> {operation_id: string, progress: number, message: string}
"error" -> {error_type: string, error_msg: string}

-- Cancellation events
"terminate" -> nil
"emergency_stop" -> nil
"operation_cancelled" -> {operation_id: string, operation_type: string}
"operation_completed" -> {operation_id: string, operation_type: string, result_data: table}

-- Diagnostic events
"run_diagnostics" -> {category: string?}
```

## Phase 10: Optimization Modules

### Memory Optimizer Module (`turtle.modules.memory_optimizer`)

Analyzes and optimizes memory usage across all modules.

```lua
-- Initialize module
MemoryOptimizer.init() -> boolean, string

-- Record memory sample
MemoryOptimizer.recordSample() -> table (sample)
-- Returns: {used, max, percentage, free, timestamp}

-- Get memory statistics
MemoryOptimizer.getStats() -> table
-- Returns: {
--   current: {used, max, percentage, free},
--   average_percentage: number,
--   peak_percentage: number,
--   samples_collected: number,
--   module_memory: table,
--   optimization_count: number
-- }

-- Perform memory optimization
MemoryOptimizer.performOptimization(strategy: number) -> boolean, number, table
-- Strategies:
--   1 = CLEAR_CACHES
--   2 = REDUCE_HISTORY
--   3 = COMPACT_TABLES
--   4 = UNLOAD_MODULES
--   5 = GARBAGE_COLLECT
-- Returns: success, freed_bytes, actions_taken

-- Get optimization recommendations
MemoryOptimizer.getRecommendations() -> table
-- Returns array of {priority, action, reason}

-- Track operation for periodic GC
MemoryOptimizer.trackOperation() -> nil

-- Start automatic monitoring
MemoryOptimizer.startMonitoring(interval: number?) -> nil
-- Default interval: 30 seconds

-- Export memory report
MemoryOptimizer.exportReport(filename: string?) -> boolean, string

-- Shutdown
MemoryOptimizer.shutdown() -> boolean
```

### Network Optimizer Module (`turtle.modules.network_optimizer`)

Reduces network traffic through batching, compression, and smart protocols.

```lua
-- Initialize module
NetworkOptimizer.init() -> boolean, string

-- Queue message for batching
NetworkOptimizer.queueMessage(recipient: number?, message: table) -> boolean
-- Returns true if queued, false to send immediately

-- Send batched messages
NetworkOptimizer.sendBatch() -> nil

-- Optimize heartbeat messages
NetworkOptimizer.optimizeHeartbeat(status_data: table) -> table
-- Returns optimized message (full, delta, or minimal)

-- Process received optimized message
NetworkOptimizer.processMessage(message: table) -> table|table[]
-- Handles batch, compressed, delta messages

-- Get optimization statistics
NetworkOptimizer.getStats() -> table
-- Returns: {
--   messages_sent: number,
--   messages_batched: number,
--   batch_ratio: number,
--   bytes_saved: number,
--   compression_ratio: number,
--   queue_size: number,
--   heartbeat_optimized: boolean
-- }

-- Handle timer events
NetworkOptimizer.handleTimer(timer_id: number) -> nil

-- Force flush queued messages
NetworkOptimizer.flush() -> nil

-- Configure settings
NetworkOptimizer.configure(settings: table) -> nil
-- Settings: {batch_timeout, max_batch_size, compression_threshold}

-- Reset statistics
NetworkOptimizer.resetStats() -> nil

-- Shutdown
NetworkOptimizer.shutdown() -> boolean
```

### Pattern Optimizer Module (`turtle.modules.pattern_optimizer`)

Optimizes mining patterns for efficiency and reduced movements.

```lua
-- Initialize module
PatternOptimizer.init() -> boolean, string

-- Optimize strip pattern based on conditions
PatternOptimizer.optimizeStripPattern(options: table) -> table
-- Adjusts spacing, length based on ore density and fuel

-- Get next efficient mining position
PatternOptimizer.getNextPosition(current_pos: table, pattern_type: string, ore_positions: table?) -> table
-- Returns optimal next position considering ore clusters

-- Cluster nearby ores
PatternOptimizer.clusterOres(ore_positions: table) -> table
-- Returns array of {center, ores, value}

-- Calculate movement efficiency
PatternOptimizer.calculateEfficiency(movements: table, blocks_mined: number) -> number
-- Returns efficiency score (0-1)

-- Optimize movement sequence
PatternOptimizer.optimizeMovements(movements: table) -> table
-- Removes redundant movements and backtracks

-- Get pattern-specific optimizations
PatternOptimizer.getPatternOptimizations(pattern_type: string) -> table

-- Cache movement pattern
PatternOptimizer.cachePattern(pattern_id: string, movements: table) -> nil

-- Get cached pattern
PatternOptimizer.getCachedPattern(pattern_id: string) -> table?

-- Update pattern statistics
PatternOptimizer.updateStats(pattern_type: string, stats: table) -> nil
-- Stats: {blocks_mined, moves, turns, ores, fuel, time, movements}

-- Get optimization recommendations
PatternOptimizer.getRecommendations(current_stats: table) -> table
-- Returns array of {pattern?, issue, suggestion, ...}

-- Clear old data
PatternOptimizer.clearOldData(max_age: number?) -> number
-- Returns number of entries cleared

-- Get statistics
PatternOptimizer.getStats() -> table
-- Returns: {
--   scanned_blocks: number,
--   cached_patterns: number,
--   pattern_stats: table,
--   memory_usage: number
-- }

-- Shutdown
PatternOptimizer.shutdown() -> boolean
```

### Performance Config Module (`turtle.modules.performance_config`)

Central configuration for memory and performance optimization settings.

```lua
-- Get setting with path
PerformanceConfig.get(path: string, default: any?) -> any
-- Example: PerformanceConfig.get("memory.path_history_size", 500)

-- Set setting with path
PerformanceConfig.set(path: string, value: any) -> nil

-- Apply low memory profile
PerformanceConfig.applyLowMemoryProfile() -> nil
-- Reduces limits and disables non-essential features

-- Apply high performance profile
PerformanceConfig.applyHighPerformanceProfile() -> nil
-- Increases limits and enables all features

-- Get adaptive settings based on memory
PerformanceConfig.getAdaptiveSettings(memory_percentage: number) -> string, table
-- Returns: level ("critical", "high", "medium", "low"), settings

-- Export configuration
PerformanceConfig.export() -> table

-- Import configuration
PerformanceConfig.import(config: table) -> boolean

-- Check if feature enabled
PerformanceConfig.isFeatureEnabled(feature: string) -> boolean

-- Check if module should be lazy loaded
PerformanceConfig.shouldLazyLoad(module_name: string) -> boolean
```

### Circular Buffer Module (`shared.circular_buffer`)

Memory-efficient circular buffer for history tracking.

```lua
-- Create new buffer
CircularBuffer.new(max_size: number) -> CircularBuffer

-- Add item to buffer
buffer:push(item: any) -> nil

-- Get item by index (1-based from oldest)
buffer:get(index: number) -> any?

-- Get most recent item
buffer:peek() -> any?

-- Get oldest item
buffer:peekOldest() -> any?

-- Remove and return most recent
buffer:pop() -> any?

-- Get all items as array
buffer:toArray() -> table

-- Get recent N items
buffer:getRecent(n: number?) -> table

-- Clear buffer
buffer:clear() -> nil

-- Get size
buffer:size() -> number

-- Check if empty
buffer:isEmpty() -> boolean

-- Check if full
buffer:isFull() -> boolean

-- Resize buffer
buffer:resize(new_size: number) -> nil

-- Find item
buffer:find(predicate: function) -> any?, number?
-- predicate: function(item, index) -> boolean

-- Filter items
buffer:filter(predicate: function) -> table

-- Apply function to all items
buffer:forEach(func: function) -> nil

-- Get memory usage estimate
buffer:getMemoryUsage() -> table
-- Returns: {buffer_size, used_slots, estimated_bytes, overhead_bytes}

-- Compact buffer
buffer:compact() -> nil

-- Iterator
buffer:iter() -> function
-- for i, item in buffer:iter() do ... end

-- Serialize for persistence
buffer:serialize() -> table

-- Deserialize from persistence
CircularBuffer.deserialize(data: table) -> CircularBuffer
```

### Code Optimizer Module (`shared.code_optimizer`)

Analyzes and suggests code optimizations.

```lua
-- Analyze code for optimization opportunities
CodeOptimizer.analyzeCode(code: string) -> table
-- Returns array of {line, code, issue, suggestion, severity}

-- Optimize table operations
CodeOptimizer.optimizeTableOperations(code: string) -> string

-- Optimize string operations
CodeOptimizer.optimizeStringOperations(code: string) -> string

-- Generate optimization report
CodeOptimizer.generateReport(file_content: string, filename: string) -> table
-- Returns: {
--   filename: string,
--   issues: table,
--   line_count: number,
--   optimization_score: number,
--   summary: table
-- }

-- Apply CC:Tweaked specific optimizations
CodeOptimizer.applyCCTweakedOptimizations(code: string) -> string

-- Get memory optimization suggestions
CodeOptimizer.getMemoryOptimizations(code: string) -> table
-- Returns array of {type, suggestion}

-- Analyze module file
CodeOptimizer.analyzeModule(module_path: string) -> table?, string?

-- Analyze entire project
CodeOptimizer.analyzeProject(base_path: string) -> table
-- Returns: {
--   total_files: number,
--   total_issues: number,
--   total_lines: number,
--   average_score: number,
--   files: table
-- }

-- Export optimization report
CodeOptimizer.exportReport(report: table, output_file: string) -> boolean
```

## Production Usage Examples

### Health Monitoring Example
```lua
local Monitoring = require("turtle.modules.monitoring")
local Alerts = require("turtle.modules.alerts")

-- Initialize
Monitoring.init()
Alerts.init()

-- Start operation with monitoring
Monitoring.startOperation("mining")

-- Mine with health checks
local function mineWithHealth()
    local healthy, issues = Monitoring.performHealthCheck()
    
    if not healthy then
        -- Critical issues found
        for _, issue in ipairs(issues) do
            if issue.severity == "critical" then
                Alerts.createError("health", issue.message)
                return false
            end
        end
    end
    
    -- Proceed with mining
    local success = turtle.dig()
    Monitoring.completeOperation("mining", success)
    
    return success
end
```

### Cancellable Operation Example
```lua
local Cancellation = require("turtle.modules.cancellation")
local Alerts = require("turtle.modules.alerts")

-- Register large operation
Cancellation.registerOperation("large_quarry", "quarry", function(op)
    -- Custom cleanup
    Navigation.returnHome()
    Inventory.storeAll()
end)

-- Start progress tracking
local progress_id = Alerts.startProgress("large_quarry", "Large Quarry Operation", 10000)

-- Mine with cancellation support
local success, reason, completed = Cancellation.cancellableLoop("large_quarry", 10000, function(i)
    -- Check and update every 10 blocks
    if i % 10 == 0 then
        Cancellation.updateProgress("large_quarry", i, "Mining block " .. i)
        Alerts.updateProgress(progress_id, i)
    end
    
    -- Create checkpoint every 100 blocks
    if i % 100 == 0 then
        Cancellation.checkpoint("large_quarry", "block_" .. i, {
            position = Navigation.getPosition(),
            fuel = turtle.getFuelLevel()
        })
    end
    
    -- Do actual mining
    turtle.dig()
    turtle.forward()
end)

if success then
    Cancellation.completeOperation("large_quarry", {blocks_mined = completed})
    Alerts.completeProgress(progress_id, "Quarry complete!")
else
    print("Operation cancelled: " .. reason)
end
```

### Diagnostic Integration Example
```lua
local Diagnostics = require("turtle.modules.diagnostics")
local Alerts = require("turtle.modules.alerts")

-- Run full diagnostics
local report = Diagnostics.runDiagnostics()

-- Check results
if report.summary.failed > 0 then
    -- Critical failures
    Alerts.create(Alerts.TYPES.ERROR, 
        "Diagnostics failed: " .. report.summary.failed .. " tests failed",
        Alerts.PRIORITY.HIGH,
        {report = report}
    )
    
    -- Show recommendations
    for _, rec in ipairs(report.recommendations) do
        print("- " .. rec)
    end
else
    Alerts.create(Alerts.TYPES.SUCCESS,
        "All diagnostics passed!",
        Alerts.PRIORITY.INFO
    )
end

-- Export for analysis
Diagnostics.exportResults("/logs/diagnostic_report.json")
```

### Memory Optimization Example
```lua
local MemoryOptimizer = require("turtle.modules.memory_optimizer")
local PerformanceConfig = require("turtle.modules.performance_config")

-- Initialize
MemoryOptimizer.init()

-- Start automatic monitoring
MemoryOptimizer.startMonitoring(30)

-- Main loop with memory tracking
while true do
    -- Track operations
    MemoryOptimizer.trackOperation()
    
    -- Check memory periodically
    if os.clock() % 60 == 0 then
        local sample = MemoryOptimizer.recordSample()
        
        if sample.percentage > 80 then
            -- Apply low memory profile
            PerformanceConfig.applyLowMemoryProfile()
            
            -- Force optimization
            MemoryOptimizer.performOptimization(1)  -- Clear caches
            MemoryOptimizer.performOptimization(5)  -- GC
        end
    end
    
    -- Do work...
    turtle.dig()
    turtle.forward()
end
```

### Network Optimization Example
```lua
local NetworkOptimizer = require("turtle.modules.network_optimizer")

-- Initialize
NetworkOptimizer.init()

-- Configure for high-latency network
NetworkOptimizer.configure({
    batch_timeout = 5,  -- 5 seconds
    max_batch_size = 20,  -- Up to 20 messages
    compression_threshold = 50  -- Compress messages > 50 bytes
})

-- Send status updates efficiently
local function sendStatus(data)
    -- Queue for batching instead of immediate send
    if NetworkOptimizer.queueMessage(control_id, data) then
        -- Message queued
        return
    end
    
    -- Fall back to immediate send if needed
    rednet.send(control_id, data)
end

-- Heartbeat with optimization
local function sendHeartbeat()
    local status = {
        id = os.getComputerID(),
        pos = Navigation.getPosition(),
        fuel = turtle.getFuelLevel(),
        status = current_status
    }
    
    -- Optimize heartbeat (sends delta or minimal)
    local optimized = NetworkOptimizer.optimizeHeartbeat(status)
    rednet.broadcast(optimized)
end
```

### Pattern Optimization Example
```lua
local PatternOptimizer = require("turtle.modules.pattern_optimizer")

-- Initialize
PatternOptimizer.init()

-- Optimize strip mining based on conditions
local function optimizedStripMine()
    local options = {
        length = 100,
        spacing = 3,
        strips = 10
    }
    
    -- Get optimized parameters
    local optimized = PatternOptimizer.optimizeStripPattern(options)
    
    -- Mine with optimization
    for strip = 1, optimized.strips do
        local movements = {}
        
        for block = 1, optimized.length do
            table.insert(movements, Navigation.getPosition())
            turtle.dig()
            turtle.forward()
            
            -- Track pattern efficiency
            if block % 10 == 0 then
                PatternOptimizer.updateStats("strip", {
                    blocks_mined = 10,
                    moves = #movements,
                    ores = countOresFound()
                })
            end
        end
        
        -- Optimize movements for return
        local return_path = PatternOptimizer.optimizeMovements(movements)
        followPath(return_path)
    end
end
```

### Circular Buffer Usage Example
```lua
local CircularBuffer = require("shared.circular_buffer")

-- Create buffer for movement history
local movement_history = CircularBuffer.new(500)

-- Track movements
local function trackMovement()
    local pos = Navigation.getPosition()
    movement_history:push({
        position = pos,
        timestamp = os.clock(),
        fuel = turtle.getFuelLevel()
    })
    
    -- Check if we're repeating movements
    local recent = movement_history:getRecent(10)
    if detectLoop(recent) then
        print("Movement loop detected!")
    end
end

-- Find when we were at a position
local function findPositionInHistory(target_pos)
    return movement_history:find(function(entry)
        return entry.position.x == target_pos.x and
               entry.position.y == target_pos.y and
               entry.position.z == target_pos.z
    end)
end

-- Analyze movement efficiency
local function analyzeMovements()
    local total_distance = 0
    local total_fuel = 0
    
    movement_history:forEach(function(entry, i)
        if i > 1 then
            local prev = movement_history:get(i - 1)
            total_distance = total_distance + 
                math.abs(entry.position.x - prev.position.x) +
                math.abs(entry.position.y - prev.position.y) +
                math.abs(entry.position.z - prev.position.z)
            total_fuel = total_fuel + (prev.fuel - entry.fuel)
        end
    end)
    
    return {
        moves = movement_history:size(),
        distance = total_distance,
        fuel_used = total_fuel,
        efficiency = total_distance / math.max(1, total_fuel)
    }
end
```