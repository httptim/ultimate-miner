# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultimate Miner is an advanced mining automation system for CC:Tweaked in Minecraft 1.21.1. The system provides intelligent mining operations with distributed control, safety protocols, and adaptive resource gathering capabilities.

## Key Architecture Components

### Modular File Structure
The codebase is organized into separate modules for maintainability:
- **Navigation Module**: GPS integration, pathfinding, position management
- **Mining Module**: Multiple mining patterns (strip, branch, spiral, quarry, adaptive)
- **Inventory Module**: Item classification, storage integration, fuel management
- **Safety Module**: Hazard detection, emergency protocols, claim protection
- **Network Module**: Multi-turtle coordination, rednet communication
- **GUI Module**: Adaptive display for different device types
- **Control Module**: Fleet management interface for computers

### Core Systems

1. **Mining Operations**
   - Resource-specific targeting with Y-level optimization
   - Area-based mining with strict boundary enforcement
   - Quantity-based gathering with automatic completion tracking
   - Multi-resource queue management

2. **Network Architecture**
   - Custom protocol: "ULTIMATE_MINER_V2" for secure communication
   - 5-10 second heartbeat intervals for performance optimization
   - Fleet size optimized for 5-20 turtles
   - Ender modem support for infinite range

3. **State Management**
   - Comprehensive persistence system for operation recovery
   - Circular buffer for path history (500-1000 moves)
   - Atomic write operations for data integrity
   - Triple backup system with checksum validation

## Development Commands

Since this is a CC:Tweaked Lua project for Minecraft, standard development commands are not applicable. However, when developing:

### Important Development Practice
**Before implementing any feature or step**, always:
1. Consider what CC:Tweaked APIs would be required
2. Check the relevant documentation links in `docs/references.md`
3. Read the specific API documentation pages to understand:
   - Available functions and their parameters
   - Events that can be used
   - Limitations and best practices
   - Example usage patterns

### Testing in CC:Tweaked
- Test individual modules in-game using the Lua interpreter
- Use `print()` statements for debugging (no console.log)
- Monitor rednet messages for network debugging

### Code Organization
- Each major component should be in its own file
- Avoid monolithic files - maintain modular structure
- Follow existing naming conventions for consistency

## Important Implementation Details

### Minecraft 1.21.1 Ore Information
Key ore blocks to detect (both stone and deepslate variants):
- Coal: Y 0 to 320 (peak at Y 96)
- Iron: Y -64 to 320 (peak at Y 16)
- Copper: Y -16 to 112 (peak at Y 48)
- Gold: Y -64 to 32 (peak at Y -16)
- Redstone: Y -64 to 16 (peak at Y -59)
- Emerald: Y -16 to 320 (mountain biomes only)
- Lapis: Y -64 to 64 (peak at Y 0)
- Diamond: Y -64 to 16 (peak at Y -59)
- Ancient Debris: Y 8 to 119 (peak at Y 15)

Always check for both variants:
- `minecraft:coal_ore` and `minecraft:deepslate_coal_ore`
- Pattern: `minecraft:<ore>_ore` and `minecraft:deepslate_<ore>_ore`

### Performance Considerations
- Memory management is critical due to CC:Tweaked limits
- Path history uses circular buffer (500-1000 moves max)
- Network updates batched at 5-10 second intervals
- Fleet operations optimized for 5-20 turtles

### Safety Protocols
- Always implement claim boundary detection
- Maintain fuel reserves for emergency returns
- Handle chunk loading edge cases
- Implement graceful failure modes

### Network Communication
- Use "ULTIMATE_MINER_V2" protocol exclusively
- Filter messages by protocol to prevent interference
- Implement heartbeat monitoring for connection health
- Support both wireless and ender modems

## CC:Tweaked API References

Key APIs used throughout the codebase:
- `turtle.*` - Movement, mining, inventory management
- `rednet.*` - Network communication between components
- `gps.*` - Position tracking and navigation
- `peripheral.*` - Storage and modem interaction
- `os.*` - Event handling and timers
- `term.*` - Display and UI rendering

Full API documentation: https://tweaked.cc/

## File Naming Conventions

Expected module structure:
- `installer.lua` - Main installation script
- `turtle_main.lua` - Main turtle control program
- `control_main.lua` - Control computer interface
- `modules/navigation.lua` - Navigation and GPS handling
- `modules/mining.lua` - Mining pattern implementations
- `modules/inventory.lua` - Inventory management
- `modules/safety.lua` - Safety protocols
- `modules/network.lua` - Network communication
- `modules/gui.lua` - User interface components

## Development Practices

### Documentation Maintenance
**ALWAYS update documentation when implementing features**:
1. Update `docs/api_reference.md` when creating/modifying module APIs
2. Update `ROADMAP.md` to mark completed tasks with [x]
3. Add usage examples to module headers
4. Document any deviations from the original plan
5. Keep error codes and event names synchronized with implementation

### Code Consistency
- Follow the patterns established in `DEVELOPMENT_GUIDE.md`
- Use consistent return patterns: `success, result/error_message`
- Maintain the same error handling approach across all modules
- Keep module interfaces clean and predictable
- Don't add dependencies between modules without updating docs

### Testing Practices
When implementing features:
1. Create simple test scripts in `tests/` directory
2. Test edge cases (no fuel, full inventory, blocked movement)
3. Verify error messages are helpful and actionable
4. Test with both regular and advanced computers/turtles
5. Validate memory usage with large operations

### Common Pitfalls to Avoid
- **Don't use `os.sleep()` in event loops** - use timers instead
- **Don't store functions in persistent state** - they can't be serialized
- **Don't assume peripheral presence** - always check before wrapping
- **Don't trust user input** - validate coordinates, ranges, etc.
- **Don't ignore chunk loading** - turtles stop in unloaded chunks

### Performance Guidelines
- **Batch Operations**: Combine multiple operations when possible
- **Limit History**: Use circular buffers (500-1000 entries max)
- **Optimize Loops**: Yield with `os.sleep(0)` every 50-100 iterations
- **Reduce Network Traffic**: Send updates every 5-10 seconds, not real-time
- **Cache Calculations**: Don't recalculate distances/paths unnecessarily

### Module Implementation Order
Due to dependencies, implement in this sequence:
1. `shared/constants.lua` - Common definitions
2. `turtle/modules/core.lua` - Base utilities
3. `turtle/modules/state.lua` - Persistence
4. `turtle/modules/config.lua` - Configuration
5. `turtle/modules/navigation.lua` - Movement
6. `turtle/modules/inventory.lua` - Item management
7. `turtle/modules/safety.lua` - Hazard detection
8. `turtle/modules/mining.lua` - Mining operations
9. Other modules can be developed in parallel

### Maintaining Module Boundaries
- Each module should be independently testable
- Modules communicate through events, not direct calls
- Shared functionality goes in `shared/` directory
- Don't create circular dependencies
- Keep modules focused on their single responsibility

### Error Message Standards
Error messages should be:
- **Specific**: "No fuel in slots 1-16" not "No fuel"
- **Actionable**: "Add fuel to continue" not "Operation failed"
- **Contextual**: Include position/state when relevant
- **Consistent**: Use the same format across modules

### Version Control Practices
- Commit working modules, not work-in-progress
- Use descriptive commit messages referencing the module/feature
- Tag milestones from the roadmap when reached
- Document breaking changes in commit messages
- Keep the installer updated with new modules

### When Stuck or Unsure
1. Check the relevant CC:Tweaked documentation links
2. Review similar implementations in existing CC:Tweaked programs
3. Test the specific API in the Lua interpreter first
4. Consider the memory and performance implications
5. Ensure the solution handles all error cases

### Integration Testing Guidelines
When modules interact:
1. Test the complete flow from user input to result
2. Verify events are emitted and handled correctly
3. Ensure error propagation works across module boundaries
4. Test state persistence across module interactions
5. Validate network messages between turtle and control

### Handling Feature Deviations
If implementation differs from the roadmap:
1. Document the change in the module header
2. Update the API reference if interfaces change
3. Note the deviation in the commit message
4. Update any dependent module plans
5. Ensure the change doesn't break existing functionality

### Installer Maintenance
When adding new modules:
1. Update `installer.lua` to include the new files
2. Add any new dependencies to the installer
3. Update device-specific installation logic
4. Test installation on both turtle and computer
5. Ensure configuration defaults are included

### Debugging Strategies
CC:Tweaked specific debugging:
1. Use `print()` liberally - it's your main debugging tool
2. Create a debug mode that shows verbose output
3. Log to files for post-mortem analysis
4. Use `textutils.serialize()` to inspect complex tables
5. Add debug commands to dump current state

### Code Review Checklist
Before considering a module complete:
- [ ] All API functions implemented as specified
- [ ] Error handling for all edge cases
- [ ] Memory-efficient implementation
- [ ] Events emitted for important state changes
- [ ] Documentation updated (API, examples, roadmap)
- [ ] Test scripts created and passing
- [ ] No hardcoded values (use config/constants)
- [ ] Installer updated if needed
- [ ] Module works independently