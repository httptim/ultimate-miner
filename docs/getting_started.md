# Getting Started with Ultimate Miner

## Installation

### Quick Install (Recommended)

1. On your turtle or computer, run:
```
wget https://github.com/httptim/ultimate-miner/raw/main/installer.lua installer
installer
```

2. Follow the on-screen prompts to install the appropriate components

### Manual Installation

1. Clone or download the repository
2. Copy the appropriate folders to your turtle/computer:
   - For turtles: `/turtle/`, `/shared/`
   - For computers: `/control/`, `/shared/`
   - For both: all folders

## First Run

### On a Turtle

1. After installation, run:
```
/turtle/main.lua
```

2. The system will initialize and show the main menu
3. Use "Test Movement" to verify the turtle is working correctly
4. Configure settings as needed

### On a Control Computer

1. After installation, run:
```
/control/main.lua
```

2. The control center will start
3. Turtles will automatically connect when they come online

## Basic Usage

### Turtle Controls

From the main menu:
- **1** - Start Mining
- **2** - Configure Settings
- **3** - Test Movement
- **4** - View Statistics
- **5** - Network Control Mode (coming soon)
- **6** - Exit

### Movement Test Options

- Test basic movements (forward, back, up, down)
- Test turning and facing directions
- Test GPS location (if available)
- Move to specific coordinates
- Return to home position

### Mining Patterns

The turtle supports several mining patterns:

#### Strip Mining
```lua
Mining.executePattern("strip", {
    length = 50,      -- Length of each strip
    spacing = 3,      -- Blocks between strips
    strips = 5,       -- Number of strips
    torch_interval = 8 -- Torch placement interval
})
```

#### Branch Mining
```lua
Mining.executePattern("branch", {
    main_length = 100,    -- Main tunnel length
    branch_length = 20,   -- Side branch length
    branch_spacing = 5,   -- Space between branches
    torch_interval = 8
})
```

#### Spiral Mining
```lua
Mining.executePattern("spiral", {
    max_radius = 32,  -- Maximum spiral radius
    layers = 3,       -- Number of layers
    torch_interval = 8
})
```

#### Quarry
```lua
Mining.executePattern("quarry", {
    width = 16,       -- Quarry width
    length = 16,      -- Quarry length
    depth = nil,      -- nil = to bedrock
    return_home = true
})
```

#### Adaptive Mining
```lua
Mining.startAdaptiveMining({
    target_ore = "diamond",  -- Specific ore to target
    max_blocks = 1000,       -- Maximum blocks to mine
    base_pattern = "branch"  -- Starting pattern
})
```

### Ore-Specific Mining

To mine for specific ores at optimal Y levels:

```lua
-- Mine for diamonds
Mining.mineForOre("diamond", {
    pattern = "branch",
    length = 100,
    return_home = true
})

-- Mine for multiple ores
Mining.startAdaptiveMining({
    ore_types = {"iron", "coal"},
    max_blocks = 2000
})
```

## Requirements

- CC:Tweaked for Minecraft 1.21.1
- Mining turtle (with pickaxe)
- Fuel in turtle inventory
- Wireless modem for network features (optional)
- GPS satellites for GPS features (optional)

## Troubleshooting

### "Module not found" errors
- Ensure all files were installed correctly
- Check that the module paths are correct
- Try reinstalling with the installer

### Movement failures
- Check turtle has fuel: `turtle.getFuelLevel()`
- Ensure turtle isn't blocked by blocks
- Verify position isn't outside safety bounds

### GPS not working
- Ensure GPS satellites are set up in your world
- Check wireless modem is attached
- Try GPS calibration from movement test menu

## Current Features

### Implemented
- ✅ Core utilities and logging
- ✅ State persistence
- ✅ Configuration management
- ✅ Basic navigation and movement
- ✅ Advanced GPS integration with recovery
- ✅ A* pathfinding algorithm
- ✅ Position tracking with history
- ✅ Fuel monitoring and planning
- ✅ Movement safety checks
- ✅ Emergency return protocols
- ✅ Home position management
- ✅ Safety radius enforcement
- ✅ Inventory management
- ✅ Mining operations
- ✅ Safety systems with hazard detection
- ✅ Storage integration
- ✅ Strip mining pattern
- ✅ Falling block support placement
- ✅ Cave-in prevention with support pillars
- ✅ Lost position recovery protocols
- ✅ Network reconnection after failure
- ✅ State recovery after restart
- ✅ Basic mob detection and combat

- ✅ Advanced mining patterns (strip, branch, spiral, quarry, adaptive)
- ✅ Y-level optimization for all ore types
- ✅ Enhanced ore vein following with 3D search
- ✅ Pattern efficiency tracking and recommendations
- ✅ Dynamic pattern adjustment based on ore density

### Coming Soon
- 🚧 Network communication
- 🚧 Fleet management
- 🚧 Control computer interface
- 🚧 Multi-turtle coordination

## Development Status

This is an active development version. Core systems are functional but many features are still being implemented. Check the [roadmap](/ROADMAP.md) for detailed progress.