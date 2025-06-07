# Ultimate Miner Example Configurations

## Table of Contents

1. [Basic Configurations](#basic-configurations)
2. [Mining Scenarios](#mining-scenarios)
3. [Performance Profiles](#performance-profiles)
4. [Network Setups](#network-setups)
5. [Safety Configurations](#safety-configurations)
6. [Fleet Configurations](#fleet-configurations)
7. [Custom Scripts](#custom-scripts)
8. [Advanced Examples](#advanced-examples)

## Basic Configurations

### Minimal Setup (Single Turtle)

**File**: `/turtle/config.json`
```json
{
  "general": {
    "autostart": false,
    "log_level": "INFO"
  },
  "movement": {
    "safe_mode": true,
    "fuel_reserve": 100,
    "movement_timeout": 5
  },
  "mining": {
    "default_pattern": "strip",
    "torch_placement": true,
    "torch_interval": 8
  },
  "inventory": {
    "auto_refuel": true,
    "drop_cobblestone": true,
    "protected_slots": [1, 2]
  }
}
```

### Standard Mining Operation

**File**: `/turtle/config.json`
```json
{
  "general": {
    "autostart": true,
    "startup_delay": 5,
    "log_level": "INFO",
    "debug_mode": false
  },
  "movement": {
    "safe_mode": true,
    "fuel_reserve": 500,
    "movement_timeout": 10,
    "pathfinding_enabled": true,
    "max_path_distance": 1000
  },
  "mining": {
    "default_pattern": "branch",
    "vein_mining": true,
    "torch_placement": true,
    "torch_interval": 8,
    "support_placement": true
  },
  "inventory": {
    "auto_refuel": true,
    "fuel_items": ["minecraft:coal", "minecraft:charcoal", "minecraft:coal_block"],
    "valuable_items": ["_ore", "minecraft:diamond", "minecraft:emerald", "minecraft:ancient_debris"],
    "drop_items": ["minecraft:cobblestone", "minecraft:dirt", "minecraft:gravel"],
    "protected_slots": [1, 2, 16]
  },
  "safety": {
    "hazard_detection": true,
    "emergency_return": true,
    "boundary_check": true,
    "max_distance": 1000
  },
  "network": {
    "enabled": true,
    "protocol": "ULTIMATE_MINER_V2",
    "heartbeat_interval": 10
  }
}
```

### High-Performance Mining

**File**: `/turtle/config.json`
```json
{
  "general": {
    "autostart": true,
    "log_level": "WARNING",
    "debug_mode": false
  },
  "movement": {
    "safe_mode": false,
    "fuel_reserve": 1000,
    "movement_timeout": 3,
    "pathfinding_enabled": true,
    "path_cache_size": 50
  },
  "mining": {
    "default_pattern": "strip",
    "vein_mining": true,
    "torch_placement": false,
    "support_placement": false,
    "aggressive_mining": true
  },
  "inventory": {
    "auto_refuel": true,
    "quick_drop": true,
    "drop_items": ["minecraft:cobblestone", "minecraft:dirt", "minecraft:gravel", "minecraft:netherrack"],
    "compact_interval": 50
  },
  "performance": {
    "batch_size": 32,
    "yield_frequency": 100,
    "gc_interval": 300,
    "detailed_metrics": false
  }
}
```

## Mining Scenarios

### Diamond Mining Setup

**Startup Script**: `/startup/diamond_miner.lua`
```lua
-- Diamond-focused mining configuration
local config = {
  target_ore = "diamond",
  optimal_y = -59,
  pattern = "branch",
  pattern_options = {
    main_length = 200,
    branch_length = 30,
    branch_spacing = 4,
    torch_interval = 8
  },
  inventory = {
    priority_items = {"minecraft:diamond", "minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"},
    auto_return_count = 20  -- Return after finding 20 diamonds
  }
}

-- Load modules
local Mining = require("turtle.modules.mining")
local Targeting = require("turtle.modules.targeting")

-- Initialize
Mining.init()
Targeting.init()

-- Add diamond target
Targeting.addTarget("diamond", 64, {priority = 10})

-- Start mining
Mining.mineForOre("diamond", config.pattern_options)
```

### Iron Farm Supply

**Configuration for iron gathering**:
```lua
-- Iron farm supplier configuration
local config = {
  targets = {
    {ore = "iron", quantity = 2000, priority = 8},
    {ore = "coal", quantity = 500, priority = 5}  -- For fuel
  },
  mining = {
    pattern = "strip",
    y_levels = {16, 48},  -- Multiple Y levels for iron
    return_frequency = 500  -- Return every 500 blocks
  },
  storage = {
    iron_chest = {x = 100, y = 64, z = 100},
    fuel_chest = {x = 100, y = 64, z = 102}
  }
}

-- Multi-level iron mining
for _, y_level in ipairs(config.mining.y_levels) do
  Navigation.moveTo({x = 0, y = y_level, z = 0})
  Mining.executePattern("strip", {
    length = 100,
    strips = 10,
    spacing = 3
  })
end
```

### Nether Mining Configuration

**File**: `/turtle/configs/nether_mining.json`
```json
{
  "environment": "nether",
  "movement": {
    "safe_mode": true,
    "lava_detection": true,
    "fall_detection": true,
    "explosion_resistance": true
  },
  "mining": {
    "target_blocks": [
      "minecraft:ancient_debris",
      "minecraft:nether_quartz_ore",
      "minecraft:nether_gold_ore"
    ],
    "pattern": "tunnel_3x3",
    "y_level": 15,
    "blast_mining": false
  },
  "safety": {
    "fire_resistance_check": true,
    "lava_bucket_ready": true,
    "emergency_blocks": ["minecraft:cobblestone", "minecraft:netherrack"],
    "max_distance": 500
  },
  "inventory": {
    "valuable_items": ["minecraft:ancient_debris", "minecraft:netherite_scrap"],
    "drop_items": ["minecraft:netherrack", "minecraft:soul_sand"],
    "protection_slots": [1, 2, 3]  -- Tools and fire resistance
  }
}
```

### Quarry Operation

**Large-scale excavation setup**:
```lua
-- Quarry configuration
local quarry_config = {
  area = {
    start = {x = 1000, y = 70, z = 1000},
    size = {width = 64, length = 64, depth = nil}  -- nil = to bedrock
  },
  operation = {
    pattern = "quarry",
    layers_per_return = 5,
    deposit_items = true,
    place_markers = true
  },
  optimization = {
    skip_air = true,
    batch_mining = true,
    ore_priority = false  -- Don't prioritize ores, clear everything
  },
  safety = {
    wall_support = true,
    water_handling = true,
    lava_handling = true
  }
}

-- Execute quarry
Area.defineArea(
  quarry_config.area.start,
  {
    x = quarry_config.area.start.x + quarry_config.area.size.width,
    y = quarry_config.area.start.y,
    z = quarry_config.area.start.z + quarry_config.area.size.length
  },
  {name = "Main Quarry", pattern = "quarry"}
)
```

## Performance Profiles

### Low Memory Profile

**For turtles with limited resources**:
```json
{
  "memory": {
    "path_history_size": 250,
    "operation_history_size": 50,
    "path_cache_size": 10,
    "alert_queue_size": 25,
    "monitoring_samples": 50
  },
  "features": {
    "detailed_metrics": false,
    "advanced_pathfinding": false,
    "vein_clustering": false,
    "hotspot_tracking": false,
    "debug_logging": false
  },
  "optimization": {
    "gc_interval": 30,
    "operations_before_gc": 50,
    "compact_frequency": 100
  }
}
```

### Balanced Profile (Default)

```json
{
  "memory": {
    "path_history_size": 500,
    "operation_history_size": 100,
    "path_cache_size": 20,
    "alert_queue_size": 50,
    "monitoring_samples": 100
  },
  "features": {
    "detailed_metrics": true,
    "advanced_pathfinding": true,
    "vein_clustering": true,
    "hotspot_tracking": true,
    "debug_logging": false
  },
  "optimization": {
    "gc_interval": 60,
    "operations_before_gc": 100,
    "compact_frequency": 200
  }
}
```

### High Performance Profile

```json
{
  "memory": {
    "path_history_size": 1000,
    "operation_history_size": 200,
    "path_cache_size": 50,
    "alert_queue_size": 100,
    "monitoring_samples": 200
  },
  "features": {
    "detailed_metrics": true,
    "advanced_pathfinding": true,
    "vein_clustering": true,
    "hotspot_tracking": true,
    "debug_logging": true,
    "pattern_caching": true,
    "predictive_mining": true
  },
  "optimization": {
    "gc_interval": 120,
    "operations_before_gc": 200,
    "compact_frequency": 500
  }
}
```

## Network Setups

### Small Fleet (5 Turtles)

**Control Computer Config**:
```json
{
  "fleet": {
    "max_turtles": 5,
    "discovery_interval": 30,
    "command_timeout": 10,
    "batch_commands": false
  },
  "network": {
    "heartbeat_timeout": 60,
    "status_update_interval": 15,
    "use_channels": false,
    "priority_messages": true
  },
  "tasks": {
    "auto_assign": true,
    "balance_workload": true,
    "task_queue_size": 20
  }
}
```

### Large Fleet (20 Turtles)

**Optimized for scale**:
```json
{
  "fleet": {
    "max_turtles": 20,
    "discovery_interval": 60,
    "command_timeout": 30,
    "batch_commands": true,
    "group_size": 5
  },
  "network": {
    "heartbeat_timeout": 120,
    "status_update_interval": 30,
    "use_channels": true,
    "channel_count": 4,
    "compression": true,
    "delta_updates": true
  },
  "tasks": {
    "auto_assign": true,
    "balance_workload": true,
    "task_queue_size": 100,
    "priority_scheduling": true
  },
  "optimization": {
    "batch_timeout": 5,
    "max_batch_size": 20,
    "message_compression": true,
    "status_aggregation": true
  }
}
```

### Multi-Control Setup

**For distributed control**:
```lua
-- Primary control configuration
local primary_config = {
  role = "primary",
  fleet_allocation = {1, 2, 3, 4, 5},  -- Turtle IDs
  task_types = {"mining", "resource_gathering"},
  backup_control = 2  -- Secondary control ID
}

-- Secondary control configuration
local secondary_config = {
  role = "secondary",
  fleet_allocation = {6, 7, 8, 9, 10},
  task_types = {"area_clearing", "construction"},
  primary_control = 1
}

-- Observer control configuration
local observer_config = {
  role = "observer",
  read_only = true,
  monitor_all = true,
  alert_forwarding = true
}
```

## Safety Configurations

### Maximum Safety

**For valuable operations**:
```json
{
  "safety": {
    "mode": "paranoid",
    "pre_movement_check": true,
    "hazard_scan_radius": 3,
    "double_check_hazards": true,
    "emergency_supplies": {
      "water_bucket": true,
      "fire_resistance": true,
      "emergency_blocks": 64,
      "food": true
    },
    "boundaries": {
      "strict": true,
      "home_radius": 500,
      "vertical_limit": 319,
      "bedrock_buffer": 5
    },
    "recovery": {
      "auto_backup": true,
      "backup_interval": 60,
      "state_verification": true,
      "position_double_check": true
    }
  }
}
```

### Balanced Safety

```json
{
  "safety": {
    "mode": "standard",
    "pre_movement_check": true,
    "hazard_scan_radius": 1,
    "boundaries": {
      "strict": false,
      "home_radius": 1000,
      "warning_distance": 900
    },
    "recovery": {
      "auto_backup": true,
      "backup_interval": 300
    }
  }
}
```

### Speed Priority

**Minimal safety for maximum speed**:
```json
{
  "safety": {
    "mode": "fast",
    "pre_movement_check": false,
    "hazard_scan_radius": 0,
    "skip_safety_checks": ["boundary", "fuel_reserve"],
    "recovery": {
      "auto_backup": false
    }
  }
}
```

## Fleet Configurations

### Mining Fleet Roles

**Specialized turtle configurations**:

#### Scout Turtle
```json
{
  "role": "scout",
  "priority": "exploration",
  "mining": {
    "pattern": "spiral",
    "quick_sample": true,
    "mark_deposits": true
  },
  "movement": {
    "speed_priority": true,
    "fuel_efficiency": false
  },
  "reporting": {
    "ore_discoveries": true,
    "cave_systems": true,
    "hazards": true
  }
}
```

#### Miner Turtle
```json
{
  "role": "miner",
  "priority": "extraction",
  "mining": {
    "pattern": "adaptive",
    "vein_mining": true,
    "thorough": true
  },
  "inventory": {
    "ore_priority": true,
    "quick_deposit": true
  }
}
```

#### Support Turtle
```json
{
  "role": "support",
  "priority": "infrastructure",
  "tasks": {
    "torch_placement": true,
    "path_clearing": true,
    "storage_setup": true,
    "fuel_distribution": true
  }
}
```

### Coordinated Operations

**Fleet working together**:
```lua
-- Fleet coordination script
local fleet_operation = {
  phase1 = {
    scouts = {1, 2},
    task = "explore_area",
    area = {x1 = 0, z1 = 0, x2 = 1000, z2 = 1000}
  },
  phase2 = {
    miners = {3, 4, 5, 6, 7, 8},
    task = "extract_deposits",
    targets = "scout_discoveries"
  },
  phase3 = {
    support = {9, 10},
    task = "setup_infrastructure",
    includes = {"lighting", "storage", "paths"}
  }
}

-- Execute phases
for phase_name, phase_config in pairs(fleet_operation) do
  Fleet.executePhase(phase_name, phase_config)
  Fleet.waitForCompletion(phase_name)
end
```

## Custom Scripts

### Auto-Smelting Operation

```lua
-- Auto-smelting integration
local smelting_config = {
  ores_to_smelt = {
    "minecraft:iron_ore",
    "minecraft:gold_ore",
    "minecraft:copper_ore"
  },
  fuel_source = "minecraft:coal",
  furnace_location = {x = 100, y = 64, z = 100}
}

-- Custom smelting function
local function autoSmelt()
  local has_ores = false
  
  -- Check for smeltable ores
  for _, ore in ipairs(smelting_config.ores_to_smelt) do
    if Inventory.getItemCount(ore) > 0 then
      has_ores = true
      break
    end
  end
  
  if has_ores then
    -- Navigate to furnace
    Navigation.moveTo(smelting_config.furnace_location)
    
    -- Deposit ores and fuel
    -- ... smelting logic ...
  end
end

-- Register as post-mining hook
Mining.registerHook("post_mining", autoSmelt)
```

### Resource Trading System

```lua
-- Automated trading post
local trading_config = {
  trade_offers = {
    {give = "minecraft:coal", amount = 64, want = "minecraft:emerald", ratio = 1},
    {give = "minecraft:iron_ingot", amount = 32, want = "minecraft:diamond", ratio = 1}
  },
  trading_post = {x = 200, y = 64, z = 200},
  check_interval = 600  -- 10 minutes
}

local function checkTrades()
  for _, offer in ipairs(trading_config.trade_offers) do
    local have = Inventory.getItemCount(offer.give)
    if have >= offer.amount then
      -- Execute trade
      Navigation.moveTo(trading_config.trading_post)
      -- ... trading logic ...
    end
  end
end
```

### Emergency Base Return

```lua
-- Emergency return system
local emergency_config = {
  triggers = {
    low_fuel = 200,
    inventory_full = 15,  -- slots
    damage_taken = true,
    lost_position = true,
    time_limit = 7200  -- 2 hours
  },
  base_location = {x = 0, y = 64, z = 0},
  emergency_fuel = "minecraft:coal",
  alert_control = true
}

-- Monitor for emergency conditions
local function checkEmergency()
  -- Low fuel
  if turtle.getFuelLevel() < emergency_config.triggers.low_fuel then
    return true, "low_fuel"
  end
  
  -- Full inventory
  if Inventory.getFreeSlots() < 1 then
    return true, "inventory_full"
  end
  
  -- Lost position
  if not Navigation.getPosition() then
    return true, "lost_position"
  end
  
  return false
end

-- Emergency return
local function emergencyReturn(reason)
  if emergency_config.alert_control then
    Network.broadcast({
      type = "emergency",
      turtle_id = os.getComputerID(),
      reason = reason,
      position = Navigation.getPosition()
    })
  end
  
  Navigation.emergencyReturn()
end
```

## Advanced Examples

### Machine Learning Pattern Adaptation

```lua
-- Adaptive pattern learning
local ml_config = {
  patterns = {"strip", "branch", "spiral"},
  metrics = {
    ores_per_block = {},
    fuel_per_ore = {},
    time_per_ore = {}
  },
  adaptation_interval = 1000,  -- blocks
  min_sample_size = 100
}

local function adaptPattern()
  local best_pattern = nil
  local best_score = 0
  
  for _, pattern in ipairs(ml_config.patterns) do
    local metrics = ml_config.metrics
    if #metrics.ores_per_block[pattern] >= ml_config.min_sample_size then
      local score = calculatePatternScore(pattern)
      if score > best_score then
        best_score = score
        best_pattern = pattern
      end
    end
  end
  
  if best_pattern then
    Mining.setDefaultPattern(best_pattern)
  end
end
```

### Distributed Task Processing

```lua
-- Distributed mining with work stealing
local distributed_config = {
  work_queue = {},
  stealing_enabled = true,
  idle_threshold = 30,  -- seconds
  task_chunks = 10
}

local function stealWork()
  -- Request work from other turtles
  Network.broadcast({
    type = "work_request",
    turtle_id = os.getComputerID(),
    capacity = Inventory.getFreeSlots()
  })
  
  -- Wait for offers
  local timeout = os.startTimer(5)
  while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" and p3 == "work_offer" then
      -- Accept work
      return p2.task
    elseif event == "timer" and p1 == timeout then
      break
    end
  end
  
  return nil
end
```

These configurations provide starting points for various mining scenarios. Adjust values based on your specific needs, server rules, and performance requirements.