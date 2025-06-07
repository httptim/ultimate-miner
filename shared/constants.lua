-- Ultimate Miner Constants
-- Shared constants and definitions used across all modules

local CONSTANTS = {}

-- Version and Protocol
CONSTANTS.VERSION = "2.2.0"
CONSTANTS.PROTOCOL = "ULTIMATE_MINER_V2"
CONSTANTS.PROTOCOL_CHANNEL = 7291  -- Unique channel for our protocol

-- Network Message Types
CONSTANTS.MSG_TYPES = {
    -- Turtle -> Control
    STATUS_UPDATE = "status_update",
    ORE_FOUND = "ore_found",
    TASK_COMPLETE = "task_complete",
    TASK_FAILED = "task_failed",
    ERROR_REPORT = "error_report",
    EMERGENCY = "emergency",
    
    -- Control -> Turtle
    COMMAND = "command",
    TASK_ASSIGN = "task_assign",
    CONFIG_UPDATE = "config_update",
    EMERGENCY_STOP = "emergency_stop",
    
    -- Bidirectional
    HEARTBEAT = "heartbeat",
    DISCOVER = "discover",
    REGISTER = "register",
    ACKNOWLEDGE = "acknowledge"
}

-- Error Codes
CONSTANTS.ERRORS = {
    -- General errors (1-99)
    UNKNOWN = 1,
    INVALID_PARAMETER = 2,
    NOT_INITIALIZED = 3,
    OPERATION_CANCELLED = 4,
    
    -- Movement errors (100-199)
    MOVEMENT_BLOCKED = 100,
    NO_FUEL = 101,
    POSITION_UNSAFE = 102,
    OUT_OF_BOUNDS = 103,
    GPS_FAILURE = 104,
    
    -- Mining errors (200-299)
    CANNOT_MINE = 200,
    TOOL_BROKEN = 201,
    INVENTORY_FULL = 202,
    NO_TOOL = 203,
    
    -- Network errors (300-399)
    CONNECTION_FAILED = 300,
    TIMEOUT = 301,
    PROTOCOL_ERROR = 302,
    NO_MODEM = 303,
    
    -- Storage errors (400-499)
    STORAGE_FULL = 400,
    NO_STORAGE_FOUND = 401,
    STORAGE_ACCESS_DENIED = 402,
    
    -- Safety errors (500-599)
    HAZARD_DETECTED = 500,
    EMERGENCY_STOP = 501,
    BOUNDARY_VIOLATION = 502,
    CLAIM_DETECTED = 503,
    FUEL_CRITICAL = 504
}

-- Minecraft 1.21.1 Ore Definitions
CONSTANTS.ORES = {
    -- Each ore has: name, stone variant, deepslate variant, optimal Y level, value tier
    COAL = {
        name = "coal",
        stone = "minecraft:coal_ore",
        deepslate = "minecraft:deepslate_coal_ore",
        optimal_y = 96,
        value = 1
    },
    IRON = {
        name = "iron",
        stone = "minecraft:iron_ore",
        deepslate = "minecraft:deepslate_iron_ore",
        optimal_y = 16,
        value = 2
    },
    COPPER = {
        name = "copper",
        stone = "minecraft:copper_ore",
        deepslate = "minecraft:deepslate_copper_ore",
        optimal_y = 48,
        value = 2
    },
    GOLD = {
        name = "gold",
        stone = "minecraft:gold_ore",
        deepslate = "minecraft:deepslate_gold_ore",
        optimal_y = -16,
        value = 3
    },
    REDSTONE = {
        name = "redstone",
        stone = "minecraft:redstone_ore",
        deepslate = "minecraft:deepslate_redstone_ore",
        optimal_y = -59,
        value = 3
    },
    EMERALD = {
        name = "emerald",
        stone = "minecraft:emerald_ore",
        deepslate = "minecraft:deepslate_emerald_ore",
        optimal_y = 100,  -- Mountain biomes
        value = 4
    },
    LAPIS = {
        name = "lapis",
        stone = "minecraft:lapis_ore",
        deepslate = "minecraft:deepslate_lapis_ore",
        optimal_y = 0,
        value = 3
    },
    DIAMOND = {
        name = "diamond",
        stone = "minecraft:diamond_ore",
        deepslate = "minecraft:deepslate_diamond_ore",
        optimal_y = -59,
        value = 5
    },
    ANCIENT_DEBRIS = {
        name = "ancient_debris",
        stone = "minecraft:ancient_debris",
        deepslate = "minecraft:ancient_debris",  -- Same block in all locations
        optimal_y = 15,
        value = 5
    }
}

-- Build ore lookup table for fast checking
CONSTANTS.ORE_BLOCKS = {}
for _, ore in pairs(CONSTANTS.ORES) do
    CONSTANTS.ORE_BLOCKS[ore.stone] = ore
    if ore.deepslate ~= ore.stone then
        CONSTANTS.ORE_BLOCKS[ore.deepslate] = ore
    end
end

-- Direction Constants
CONSTANTS.DIRECTIONS = {
    NORTH = 0,
    EAST = 1,
    SOUTH = 2,
    WEST = 3,
    UP = 4,
    DOWN = 5
}

-- Direction Vectors
CONSTANTS.DIRECTION_VECTORS = {
    [0] = {x = 0, y = 0, z = -1},  -- North
    [1] = {x = 1, y = 0, z = 0},   -- East
    [2] = {x = 0, y = 0, z = 1},   -- South
    [3] = {x = -1, y = 0, z = 0},  -- West
    [4] = {x = 0, y = 1, z = 0},   -- Up
    [5] = {x = 0, y = -1, z = 0}   -- Down
}

-- Item Classifications
CONSTANTS.ITEM_TYPES = {
    ORE = "ore",
    FUEL = "fuel",
    VALUABLE = "valuable",
    TOOL = "tool",
    TORCH = "torch",
    BUILDING = "building",
    JUNK = "junk"
}

-- Fuel Values (in movement units)
CONSTANTS.FUEL_VALUES = {
    ["minecraft:coal"] = 80,
    ["minecraft:charcoal"] = 80,
    ["minecraft:coal_block"] = 800,
    ["minecraft:dried_kelp_block"] = 200,
    ["minecraft:blaze_rod"] = 120,
    ["minecraft:lava_bucket"] = 1000,
    ["minecraft:stick"] = 5,
    ["minecraft:wooden_slab"] = 7.5,
    ["minecraft:planks"] = 15,
    ["minecraft:log"] = 15,
    ["minecraft:log2"] = 15
}

-- Default Configuration Values
CONSTANTS.DEFAULTS = {
    -- Safety
    SAFETY_RADIUS = 100,
    FUEL_RESERVE = 500,
    EMERGENCY_FUEL = 100,
    
    -- Mining
    TORCH_INTERVAL = 8,
    STRIP_SPACING = 3,
    BRANCH_LENGTH = 50,
    QUARRY_SIZE = 16,
    
    -- Network
    HEARTBEAT_INTERVAL = 5,
    STATUS_UPDATE_INTERVAL = 10,
    NETWORK_TIMEOUT = 30,
    
    -- Performance
    MAX_PATH_HISTORY = 1000,
    MAX_ORE_HISTORY = 500,
    YIELD_INTERVAL = 50,
    
    -- UI
    SCREEN_UPDATE_INTERVAL = 0.5,
    DEBUG_MODE = false
}

-- Limits and Thresholds
CONSTANTS.LIMITS = {
    MAX_INVENTORY = 16,
    MAX_FUEL = 20000,
    MIN_SAFE_Y = -59,  -- Bedrock starts at -64, safe mining at -59
    MAX_SAFE_Y = 320,
    MAX_DISTANCE = 10000,
    MAX_MINING_TIME = 3600,  -- 1 hour
    MAX_MESSAGE_SIZE = 4096
}

-- Mining Patterns
CONSTANTS.PATTERNS = {
    STRIP = "strip",
    BRANCH = "branch",
    SPIRAL = "spiral",
    QUARRY = "quarry",
    TUNNEL3X3 = "tunnel3x3",
    ADAPTIVE = "adaptive"
}

-- Log Levels
CONSTANTS.LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    CRITICAL = 5
}

-- Storage Block Types
CONSTANTS.STORAGE_BLOCKS = {
    ["minecraft:chest"] = true,
    ["minecraft:trapped_chest"] = true,
    ["minecraft:barrel"] = true,
    ["minecraft:shulker_box"] = true,
    ["minecraft:white_shulker_box"] = true,
    ["minecraft:orange_shulker_box"] = true,
    ["minecraft:magenta_shulker_box"] = true,
    ["minecraft:light_blue_shulker_box"] = true,
    ["minecraft:yellow_shulker_box"] = true,
    ["minecraft:lime_shulker_box"] = true,
    ["minecraft:pink_shulker_box"] = true,
    ["minecraft:gray_shulker_box"] = true,
    ["minecraft:light_gray_shulker_box"] = true,
    ["minecraft:cyan_shulker_box"] = true,
    ["minecraft:purple_shulker_box"] = true,
    ["minecraft:blue_shulker_box"] = true,
    ["minecraft:brown_shulker_box"] = true,
    ["minecraft:green_shulker_box"] = true,
    ["minecraft:red_shulker_box"] = true,
    ["minecraft:black_shulker_box"] = true
}

-- Hazardous Blocks
CONSTANTS.HAZARDS = {
    ["minecraft:lava"] = "lava",
    ["minecraft:flowing_lava"] = "lava",
    ["minecraft:water"] = "water",
    ["minecraft:flowing_water"] = "water",
    ["minecraft:fire"] = "fire",
    ["minecraft:magma_block"] = "damage",
    ["minecraft:cactus"] = "damage"
}

return CONSTANTS