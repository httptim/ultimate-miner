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