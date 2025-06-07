# Ultimate Miner User Manual

## Table of Contents

1. [Introduction](#introduction)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Getting Started](#getting-started)
5. [Turtle Operations](#turtle-operations)
6. [Control Computer Operations](#control-computer-operations)
7. [Mining Patterns](#mining-patterns)
8. [Advanced Features](#advanced-features)
9. [Performance Optimization](#performance-optimization)
10. [Troubleshooting](#troubleshooting)
11. [Command Reference](#command-reference)
12. [Best Practices](#best-practices)

## Introduction

Ultimate Miner is a comprehensive mining automation system for CC:Tweaked in Minecraft 1.21.1. It transforms basic ComputerCraft turtles into an intelligent fleet of autonomous miners with centralized control, advanced safety features, and adaptive mining strategies.

### Key Features

- **Autonomous Mining**: Multiple mining patterns with intelligent ore detection
- **Fleet Management**: Control up to 20 turtles from a central computer
- **Safety Systems**: Hazard detection, emergency protocols, and boundary protection
- **Resource Targeting**: Mine specific ores with quantity goals
- **Area-Based Mining**: Define and mine specific regions
- **Smart Mining**: Adaptive strategies based on ore density
- **Production Features**: Health monitoring, data integrity, and graceful error handling
- **Performance Optimization**: Memory management and network traffic reduction

## System Requirements

### Minecraft Requirements
- Minecraft 1.21.1
- CC:Tweaked mod installed
- Mining turtles (with diamond pickaxe)

### Hardware Requirements
- **Turtles**: Mining turtles with fuel
- **Control Computer**: Advanced computer (recommended) or standard computer
- **Network**: Wireless modems or ender modems
- **GPS**: GPS satellite array (optional but recommended)

### Performance Recommendations
- Maximum 20 turtles per control computer
- Chunk loaders for large operations
- Ender modems for long-range operations

## Installation

### Quick Install (Recommended)

1. On your turtle or computer, run:
```
wget https://github.com/httptim/ultimate-miner/raw/main/installer.lua installer
installer
```

2. Select installation type:
   - `1` - Install for current device (turtle or computer)
   - `2` - Install both turtle and control components
   - `3` - Custom installation

3. Follow the on-screen prompts

### Manual Installation

1. Download the Ultimate Miner repository
2. Copy files to your ComputerCraft computer:
   - For turtles: `/turtle/` and `/shared/` directories
   - For control computers: `/control/` and `/shared/` directories
3. Run the main program:
   - Turtles: `/turtle/main.lua`
   - Control: `/control/main.lua`

## Getting Started

### First-Time Setup for Turtles

1. **Place the turtle** in your desired mining location
2. **Add fuel** to the turtle's inventory (coal, lava buckets, etc.)
3. **Run the program**: `/turtle/main.lua`
4. **Configure settings** from the main menu:
   - Set home position
   - Configure safety radius
   - Set mining preferences

### First-Time Setup for Control Computer

1. **Place the computer** in a central location
2. **Attach a modem** (wireless or ender)
3. **Run the program**: `/control/main.lua`
4. **Wait for turtles** to connect automatically

### GPS Setup (Optional)

For precise positioning:
1. Set up GPS satellites at Y=255
2. Each satellite needs a wireless modem
3. Run `gps host` on each satellite
4. Test with `gps locate` on your turtle

## Turtle Operations

### Main Menu Options

1. **Start Mining** - Begin mining with selected pattern
2. **Configure Settings** - Adjust mining parameters
3. **Test Movement** - Verify turtle functionality
4. **View Statistics** - Check mining performance
5. **Network Control Mode** - Connect to control computer
6. **Run Diagnostics** - System health check
7. **Exit** - Safely shutdown

### Basic Mining Commands

#### Start Strip Mining
```
/turtle/main.lua mine strip
```
Options:
- `length`: Strip length (default: 50)
- `spacing`: Space between strips (default: 3)
- `strips`: Number of strips (default: 5)

#### Mine Specific Ore
```
/turtle/main.lua target diamond 64
```
Targets 64 diamond ore blocks at optimal Y-level.

#### Mine Area
```
/turtle/main.lua area 100,100 200,200
```
Mines rectangular area from coordinates 100,100 to 200,200.

### Safety Features

The turtle includes multiple safety systems:

- **Fuel Monitoring**: Maintains emergency fuel reserve
- **Hazard Detection**: Detects lava, water, and falling blocks
- **Boundary Protection**: Respects configured safety radius
- **Emergency Return**: Returns home when critical
- **Cave-in Prevention**: Places support blocks

## Control Computer Operations

### Dashboard Overview

The control computer displays:
- Connected turtle count
- Fleet status summary
- Active operations
- Resource totals
- Recent alerts

### Fleet Management

#### View All Turtles
Press `1` from main menu to see:
- Turtle ID and name
- Current position
- Fuel level
- Status (idle, mining, returning)
- Blocks mined

#### Individual Turtle Control
Select a turtle to:
- View detailed information
- Send commands
- Assign tasks
- Emergency stop

#### Fleet-Wide Commands
- **Emergency Stop All**: Immediately stops all turtles
- **Return All Home**: Recalls entire fleet
- **Assign Pattern**: Apply mining pattern to all

### Task Management

#### Create Resource Task
```
/control/main.lua task resource diamond 1000
```
Creates task to mine 1000 diamonds, automatically assigned to available turtles.

#### Create Area Task
```
/control/main.lua task area 0,0,0 64,16,64 quarry
```
Creates quarry task for specified area.

#### Monitor Tasks
View task progress:
- Queued tasks
- Active assignments
- Completion status
- Resource totals

## Mining Patterns

### Strip Mining

Most efficient for finding ores at specific Y-levels.

```lua
pattern = "strip"
options = {
    length = 50,      -- Length of each strip
    spacing = 3,      -- Blocks between strips  
    strips = 5,       -- Number of strips
    torch_interval = 8 -- Torch placement frequency
}
```

**Best for**: Diamonds, Redstone, Gold
**Efficiency**: High coverage, moderate speed

### Branch Mining

Main tunnel with side branches.

```lua
pattern = "branch"
options = {
    main_length = 100,   -- Main tunnel length
    branch_length = 20,  -- Side branch length
    branch_spacing = 5,  -- Space between branches
    torch_interval = 8
}
```

**Best for**: General mining, exploring
**Efficiency**: Good coverage, easy navigation

### Spiral Mining

Expanding spiral pattern from center.

```lua
pattern = "spiral"
options = {
    max_radius = 32,  -- Maximum spiral radius
    layers = 3,       -- Vertical layers
    torch_interval = 8
}
```

**Best for**: Surface deposits, area clearing
**Efficiency**: Complete coverage, slow

### Quarry

Complete excavation of rectangular area.

```lua
pattern = "quarry"
options = {
    width = 16,       -- Quarry width
    length = 16,      -- Quarry length  
    depth = nil,      -- nil = to bedrock
    return_home = true
}
```

**Best for**: Maximum resource extraction
**Efficiency**: 100% coverage, very slow

### 3x3 Tunnel

Creates large tunnels for access.

```lua
pattern = "tunnel_3x3"
options = {
    length = 50,
    torch_interval = 8,
    support_interval = 16
}
```

**Best for**: Access tunnels, mob farms
**Efficiency**: Low for mining, high for access

### Adaptive Mining

Automatically adjusts pattern based on ore density.

```lua
pattern = "adaptive"
options = {
    target_ore = "diamond",
    max_blocks = 1000,
    base_pattern = "branch"
}
```

**Best for**: Specific ore targeting
**Efficiency**: Variable, optimizes over time

## Advanced Features

### Resource Targeting

Mine specific resources with quantity goals:

```lua
-- Target multiple resources
/turtle/main.lua target add iron 1000 priority:5
/turtle/main.lua target add diamond 64 priority:9
/turtle/main.lua target add emerald 32 priority:7
```

Features:
- Priority queue processing
- Progress tracking
- Time estimation
- Automatic Y-level optimization

### Area-Based Mining

Define specific mining regions:

```lua
-- Define named area
/turtle/main.lua area define "North Quarry" 1000,1000 1064,1064
/turtle/main.lua area mine "North Quarry"
```

Features:
- Boundary enforcement
- Chunk loading awareness
- Section-based progress
- Saturation detection

### Smart Mining

Intelligent mining with adaptive strategies:

```lua
/turtle/main.lua smart mine diamond,emerald
```

Features:
- Dynamic Y-level adjustment
- Pattern switching based on density
- Scarcity handling
- Alternative depth exploration

### Production Monitoring

Real-time health and performance tracking:

```lua
-- View health status
/turtle/main.lua health

-- Run diagnostics
/turtle/main.lua diagnostics

-- View performance metrics
/turtle/main.lua metrics
```

Monitors:
- Fuel levels and consumption
- Inventory status
- Movement blocks
- Network connectivity
- Ghost state detection

### Data Integrity

Triple backup system protects all data:
- Automatic backups
- Checksum validation
- Corruption recovery
- Atomic writes

### Alert System

Prioritized notifications:
- **Critical**: Immediate attention required
- **High**: Important issues
- **Medium**: Performance concerns
- **Low**: Informational
- **Info**: General updates

### Graceful Cancellation

Cancel any operation with Ctrl+T:
- Saves current progress
- Executes cleanup
- Returns to safe state
- Preserves data

## Performance Optimization

### Memory Management

The system automatically manages memory:

1. **Circular Buffers**: Limited history sizes
2. **Lazy Loading**: Modules loaded on demand
3. **Garbage Collection**: Periodic cleanup
4. **Cache Management**: Automatic cache clearing

### Network Optimization

Reduces network traffic through:

1. **Message Batching**: Groups multiple messages
2. **Delta Updates**: Sends only changes
3. **Compression**: Reduces message size
4. **Smart Heartbeats**: Adaptive frequency

### Performance Profiles

#### High Performance Mode
```lua
/turtle/main.lua performance high
```
- All features enabled
- Detailed tracking
- Maximum cache sizes

#### Balanced Mode (Default)
```lua
/turtle/main.lua performance balanced
```
- Standard features
- Moderate caching
- Regular cleanup

#### Low Memory Mode
```lua
/turtle/main.lua performance low
```
- Essential features only
- Minimal caching
- Aggressive cleanup

### Monitoring Performance

View performance metrics:
```lua
/turtle/main.lua performance stats
```

Shows:
- Memory usage
- Operation rates
- Network statistics
- Cache efficiency

## Troubleshooting

### Common Issues

#### Turtle Won't Move
1. Check fuel level: `turtle.getFuelLevel()`
2. Verify no obstructions
3. Check movement permissions
4. Run diagnostics: `/turtle/main.lua diagnostics movement`

#### Lost GPS Signal
1. Verify GPS satellites are running
2. Check modem attachment
3. Test with `gps locate`
4. Use manual position: `/turtle/main.lua gps manual x y z`

#### Network Connection Failed
1. Check modem is attached
2. Verify modem is open
3. Check protocol: "ULTIMATE_MINER_V2"
4. Restart network: `/turtle/main.lua network restart`

#### Memory Issues
1. Check memory usage: `/turtle/main.lua memory stats`
2. Clear caches: `/turtle/main.lua memory clear`
3. Reduce history sizes
4. Switch to low memory profile

#### Mining Pattern Stuck
1. Emergency stop: Ctrl+T
2. Check for bedrock/protected blocks
3. Verify area boundaries
4. Clear pattern cache

### Diagnostic Tools

Run comprehensive diagnostics:
```lua
/turtle/main.lua diagnostics all
```

Categories:
- **System**: API and peripheral checks
- **Movement**: Motion capability
- **Inventory**: Storage space
- **Network**: Connection status
- **Storage**: Container access
- **Safety**: Hazard detection
- **Performance**: Speed tests
- **Data**: File integrity

### Recovery Procedures

#### Lost Position Recovery
1. Turtle attempts GPS fix
2. Checks saved state
3. Looks for landmarks
4. Uses movement history
5. Requests manual position

#### Network Reconnection
1. Automatic retry every 30 seconds
2. Broadcasts discovery
3. Re-registers with control
4. Resumes operations

#### Data Corruption Recovery
1. Attempts primary file read
2. Checks triple backups
3. Validates checksums
4. Restores from backup
5. Uses defaults if needed

## Command Reference

### Turtle Commands

#### Mining Commands
- `mine <pattern> [options]` - Start mining with pattern
- `stop` - Stop current operation
- `pause` - Pause operation
- `resume` - Resume operation

#### Target Commands
- `target <ore> <quantity> [priority:N]` - Add resource target
- `target list` - Show current targets
- `target clear` - Clear all targets

#### Area Commands
- `area <x1,z1> <x2,z2> [options]` - Mine area
- `area define <name> <x1,z1> <x2,z2>` - Define named area
- `area list` - List defined areas

#### Status Commands
- `status` - Show current status
- `stats` - Show statistics
- `inventory` - List inventory
- `fuel` - Show fuel level

#### Configuration Commands
- `config set <key> <value>` - Set configuration
- `config get <key>` - Get configuration
- `config list` - List all settings

#### Utility Commands
- `home` - Return to home position
- `refuel [slot]` - Refuel from inventory
- `deposit` - Deposit items to storage
- `diagnostics [category]` - Run diagnostics

### Control Computer Commands

#### Fleet Commands
- `fleet status` - Show all turtles
- `fleet stop` - Emergency stop all
- `fleet return` - Return all home

#### Task Commands
- `task create <type> [options]` - Create task
- `task assign <task_id> <turtle_id>` - Assign task
- `task status` - Show task status
- `task cancel <task_id>` - Cancel task

#### Turtle Commands
- `turtle <id> status` - Individual status
- `turtle <id> command <cmd>` - Send command
- `turtle <id> stop` - Stop individual

#### Monitoring Commands
- `monitor health` - Fleet health
- `monitor performance` - Performance metrics
- `monitor resources` - Resource totals

## Best Practices

### Fuel Management
1. Keep 20% fuel reserve minimum
2. Use lava buckets for efficiency
3. Set up fuel stations
4. Monitor consumption rates

### Inventory Management
1. Regular deposits to storage
2. Keep tool slots protected
3. Filter valuable items
4. Use ender chests for remote storage

### Network Setup
1. Use ender modems for range
2. Position control centrally
3. Set up redundant connections
4. Monitor heartbeat status

### Mining Efficiency
1. Mine at optimal Y-levels:
   - Diamond: Y -59
   - Iron: Y 16  
   - Gold: Y -16
   - Copper: Y 48

2. Use appropriate patterns:
   - Strip for specific ores
   - Quarry for maximum yield
   - Adaptive for exploration

3. Coordinate fleet operations:
   - Assign different areas
   - Stagger operations
   - Share discoveries

### Safety Considerations
1. Set appropriate boundaries
2. Test in creative first
3. Back up important areas
4. Monitor chunk loading
5. Respect server rules

### Performance Tips
1. Limit active turtles to 20
2. Use batched operations
3. Clear old data regularly
4. Monitor memory usage
5. Optimize patterns for your needs

## Conclusion

Ultimate Miner provides a comprehensive mining solution with advanced features for efficiency, safety, and scalability. Follow this manual for optimal results and refer to the troubleshooting section for common issues.

For additional support:
- GitHub Issues: https://github.com/httptim/ultimate-miner/issues
- API Documentation: See `/docs/api_reference.md`
- Examples: See `/docs/examples/`

Happy mining!