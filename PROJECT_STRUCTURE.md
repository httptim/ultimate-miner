# Ultimate Miner Project Structure

## Directory Layout

```
ultimate-miner/
├── installer.lua                 # Main installation script
├── README.md                     # Project documentation
├── ROADMAP.md                    # Development roadmap
├── CLAUDE.md                     # Claude Code guidance
├── PROJECT_STRUCTURE.md          # This file
├── LICENSE                       # License file
│
├── turtle/                       # Turtle-specific components
│   ├── main.lua                  # Main turtle program entry point
│   ├── modules/                  # Core turtle modules
│   │   ├── core.lua              # Core utilities and helpers
│   │   ├── navigation.lua        # Movement and pathfinding
│   │   ├── mining.lua            # Mining operations and patterns
│   │   ├── inventory.lua         # Inventory management
│   │   ├── safety.lua            # Safety protocols and hazard detection
│   │   ├── storage.lua           # Storage integration
│   │   ├── network.lua           # Network communication
│   │   ├── state.lua             # State persistence
│   │   └── config.lua            # Configuration management
│   └── patterns/                 # Mining pattern implementations
│       ├── strip.lua             # Strip mining pattern
│       ├── branch.lua            # Branch mining pattern
│       ├── spiral.lua            # Spiral mining pattern
│       ├── quarry.lua            # Quarry pattern
│       ├── tunnel3x3.lua         # 3x3 tunnel pattern
│       └── adaptive.lua          # Adaptive pattern selection
│
├── control/                      # Control computer components
│   ├── main.lua                  # Main control program entry point
│   ├── modules/                  # Control computer modules
│   │   ├── ui.lua                # User interface framework
│   │   ├── fleet.lua             # Fleet management
│   │   ├── network.lua           # Network coordination
│   │   ├── monitor.lua           # Monitoring and analytics
│   │   ├── tasks.lua             # Task distribution
│   │   └── config.lua            # Configuration management
│   └── ui/                       # UI components
│       ├── dashboard.lua         # Main dashboard
│       ├── turtle_list.lua       # Turtle management interface
│       ├── resource_manager.lua  # Resource targeting interface
│       ├── area_manager.lua      # Area assignment interface
│       └── settings.lua          # Settings interface
│
├── shared/                       # Shared libraries
│   ├── constants.lua             # Shared constants and definitions
│   ├── protocol.lua              # Network protocol definitions
│   ├── utils.lua                 # Shared utility functions
│   ├── ores.lua                  # Ore definitions for 1.21.1
│   └── messages.lua              # Message format definitions
│
├── docs/                         # Documentation
│   ├── references.md             # CC:Tweaked API references
│   ├── user_manual.md            # User manual
│   ├── api_reference.md          # Module API documentation
│   ├── troubleshooting.md        # Troubleshooting guide
│   └── examples/                 # Example configurations
│       ├── basic_setup.md        # Basic setup guide
│       ├── fleet_setup.md        # Fleet setup guide
│       └── advanced_config.md    # Advanced configuration
│
├── tests/                        # Test files
│   ├── turtle/                   # Turtle module tests
│   │   ├── test_navigation.lua   # Navigation tests
│   │   ├── test_mining.lua       # Mining tests
│   │   └── test_safety.lua       # Safety system tests
│   └── control/                  # Control module tests
│       ├── test_fleet.lua        # Fleet management tests
│       └── test_network.lua      # Network tests
│
└── examples/                     # Example scripts
    ├── simple_miner.lua          # Simple mining example
    ├── fleet_example.lua         # Fleet control example
    └── custom_pattern.lua        # Custom pattern example
```

## Module Descriptions

### Turtle Modules

#### Core Module (`turtle/modules/core.lua`)
- Vector mathematics and position handling
- Event system wrapper
- Logging functionality
- Common helper functions
- Error handling utilities

#### Navigation Module (`turtle/modules/navigation.lua`)
- Movement primitives (forward, back, up, down, turn)
- GPS integration and coordinate management
- Pathfinding algorithms (A*)
- Obstacle detection and avoidance
- Distance and fuel calculations
- Path history management

#### Mining Module (`turtle/modules/mining.lua`)
- Block breaking with safety checks
- Ore detection for all 1.21.1 ores
- Mining pattern execution
- Torch placement logic
- Vein mining capabilities
- Efficiency tracking

#### Inventory Module (`turtle/modules/inventory.lua`)
- Item classification system
- Slot management and optimization
- Fuel detection and consumption
- Tool preservation
- Item prioritization
- Emergency item dropping

#### Safety Module (`turtle/modules/safety.lua`)
- Hazard detection (lava, water, void)
- Falling block handling
- Mob detection and combat
- Fuel monitoring and reserves
- Emergency protocols
- Claim boundary detection

#### Storage Module (`turtle/modules/storage.lua`)
- Container detection and validation
- Item depositing logic
- Multi-container support
- Storage trip planning
- Inventory optimization

#### Network Module (`turtle/modules/network.lua`)
- Rednet initialization and management
- Message sending and receiving
- Protocol handling
- Heartbeat system
- Status reporting
- Command processing

#### State Module (`turtle/modules/state.lua`)
- Persistent state management
- Save/load functionality
- State validation
- Migration between versions
- Backup management

#### Config Module (`turtle/modules/config.lua`)
- Configuration loading and saving
- Default values
- User preference management
- Dynamic reconfiguration

### Control Computer Modules

#### UI Module (`control/modules/ui.lua`)
- Display detection and adaptation
- Input handling (keyboard/mouse)
- Screen layout management
- Color support detection
- Widget system

#### Fleet Module (`control/modules/fleet.lua`)
- Turtle registration and tracking
- Status monitoring
- Command distribution
- Load balancing
- Performance tracking

#### Network Module (`control/modules/network.lua`)
- Network coordination
- Message routing
- Protocol management
- Discovery system
- Connection monitoring

#### Monitor Module (`control/modules/monitor.lua`)
- Real-time status tracking
- Performance analytics
- Resource discovery rates
- Historical data management
- Alert generation

#### Tasks Module (`control/modules/tasks.lua`)
- Task queue management
- Job distribution
- Priority handling
- Progress tracking
- Completion detection

### Shared Libraries

#### Constants (`shared/constants.lua`)
- Protocol version
- Message types
- Block IDs
- Default configurations
- Limits and thresholds

#### Protocol (`shared/protocol.lua`)
- Message format specifications
- Protocol version handling
- Encryption/authentication
- Error codes

#### Utils (`shared/utils.lua`)
- String manipulation
- Table utilities
- Math helpers
- Time functions
- Validation helpers

#### Ores (`shared/ores.lua`)
- Complete ore list for 1.21.1
- Y-level distributions
- Value classifications
- Mining priorities

#### Messages (`shared/messages.lua`)
- Message constructors
- Message parsers
- Validation functions
- Type definitions

## Development Guidelines

### File Naming
- Use lowercase with underscores
- Descriptive names that indicate purpose
- Lua extension for all code files
- Markdown for documentation

### Code Organization
- One primary purpose per file
- Clear module boundaries
- Shared code in shared/ directory
- No circular dependencies

### Module Interface
- Each module exports a table
- Clear public API
- Private functions prefixed with underscore
- Comprehensive error handling

### Documentation
- Each module has header comments
- Function documentation includes parameters and returns
- Complex algorithms explained
- Usage examples provided

## Build Process

The installer.lua script handles:
1. Device type detection
2. Appropriate module selection
3. Dependency resolution
4. File installation
5. Initial configuration
6. First-run setup

## Testing Strategy

### Unit Tests
- Individual function testing
- Module isolation
- Mock dependencies
- Edge case coverage

### Integration Tests
- Module interaction
- Network communication
- State persistence
- Error propagation

### System Tests
- Full turtle operations
- Fleet coordination
- Performance testing
- Stress testing