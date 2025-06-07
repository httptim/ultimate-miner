# Ultimate Miner Troubleshooting Guide

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Installation Issues](#installation-issues)
3. [Movement Problems](#movement-problems)
4. [Mining Issues](#mining-issues)
5. [Network Problems](#network-problems)
6. [GPS Issues](#gps-issues)
7. [Memory and Performance](#memory-and-performance)
8. [Storage Problems](#storage-problems)
9. [Error Messages](#error-messages)
10. [Recovery Procedures](#recovery-procedures)
11. [Advanced Debugging](#advanced-debugging)
12. [FAQ](#frequently-asked-questions)

## Quick Diagnostics

### Run Built-in Diagnostics

```lua
/turtle/main.lua diagnostics all
```

This checks:
- System APIs
- Movement capability
- Inventory status
- Network connectivity
- Storage access
- Safety systems
- Performance metrics
- Data integrity

### Quick Health Check

```lua
/turtle/main.lua health check
```

Shows:
- Fuel level
- Inventory space
- Position status
- Network status
- Current operation

## Installation Issues

### HTTP API Not Enabled

**Symptoms**:
- "HTTP API not enabled" error
- Cannot download installer
- Web requests fail

**Solution**:
1. Exit Minecraft completely
2. Navigate to your Minecraft instance folder
3. Edit `config/computercraft-common.toml` (Forge) or `config/computercraft-server.toml` (Fabric)
4. Find and change:
   ```toml
   enabled = true  # Under [http]
   ```
5. Save and restart Minecraft

### Installer Fails to Download

**Symptoms**:
- wget returns error
- Connection timeout
- 404 error

**Solutions**:

1. **Check URL**:
   ```lua
   wget https://github.com/httptim/ultimate-miner/raw/main/installer.lua installer
   ```

2. **Use alternative download**:
   ```lua
   -- If GitHub is blocked
   pastebin run [PASTEBIN_CODE]
   ```

3. **Manual download**:
   - Download files on external computer
   - Transfer via disk drive

### Files Not Found After Installation

**Symptoms**:
- "No such file" errors
- Missing modules
- Program won't start

**Solutions**:

1. **Verify installation**:
   ```lua
   ls /turtle/
   ls /shared/
   ```

2. **Check installation type**:
   - Turtle needs: `/turtle/` and `/shared/`
   - Computer needs: `/control/` and `/shared/`

3. **Reinstall**:
   ```lua
   installer
   -- Choose "Reinstall/Update"
   ```

## Movement Problems

### Turtle Won't Move

**Symptoms**:
- Movement commands fail
- Turtle appears stuck
- "Movement obstructed" errors

**Solutions**:

1. **Check fuel**:
   ```lua
   print(turtle.getFuelLevel())
   -- If 0 or low:
   turtle.refuel()
   ```

2. **Check for obstructions**:
   ```lua
   print(turtle.detect())      -- Front
   print(turtle.detectUp())    -- Above
   print(turtle.detectDown())  -- Below
   ```

3. **Verify permissions**:
   - Check if area is protected
   - Verify claim boundaries
   - Test in different location

4. **Reset position**:
   ```lua
   /turtle/main.lua position reset
   ```

### Lost Position / GPS Mismatch

**Symptoms**:
- Position shows as unknown
- GPS coordinates wrong
- Turtle mining in wrong location

**Solutions**:

1. **Recalibrate GPS**:
   ```lua
   /turtle/main.lua gps calibrate
   ```

2. **Set manual position**:
   ```lua
   /turtle/main.lua gps manual <x> <y> <z> [facing]
   -- facing: 0=north, 1=east, 2=south, 3=west
   ```

3. **Use recovery**:
   ```lua
   /turtle/main.lua recover position
   ```

### Movement Too Slow

**Symptoms**:
- Turtle moves slowly
- Long pauses between moves
- Inefficient pathing

**Solutions**:

1. **Check performance mode**:
   ```lua
   /turtle/main.lua performance high
   ```

2. **Disable extra features**:
   ```lua
   -- In config
   detailed_metrics = false
   advanced_pathfinding = false
   ```

3. **Clear path cache**:
   ```lua
   /turtle/main.lua cache clear paths
   ```

## Mining Issues

### Not Mining Ores

**Symptoms**:
- Turtle skips ore blocks
- Only mines stone
- Missing valuable resources

**Solutions**:

1. **Update ore detection**:
   ```lua
   -- Check ore list includes all variants
   /turtle/main.lua ores list
   ```

2. **Verify block names**:
   ```lua
   -- While facing ore:
   local success, data = turtle.inspect()
   print(data.name)
   ```

3. **Check pattern settings**:
   - Some patterns skip blocks
   - Verify scan radius settings

### Mining Pattern Stuck

**Symptoms**:
- Pattern doesn't progress
- Turtle loops same area
- Never completes

**Solutions**:

1. **Emergency stop**:
   ```
   Hold Ctrl+T
   ```

2. **Clear pattern state**:
   ```lua
   /turtle/main.lua pattern reset
   ```

3. **Check boundaries**:
   - Verify area boundaries
   - Check for bedrock
   - Look for protected blocks

### Inventory Fills Too Quickly

**Symptoms**:
- Frequent returns to storage
- Mining interrupted
- Low efficiency

**Solutions**:

1. **Configure filters**:
   ```lua
   -- Drop unwanted items
   /turtle/main.lua config set drop_items "cobblestone,dirt,gravel"
   ```

2. **Use better storage**:
   - Ender chest in inventory
   - Closer storage location
   - Multiple storage points

3. **Optimize inventory**:
   ```lua
   /turtle/main.lua inventory optimize
   ```

## Network Problems

### Can't Connect to Control Computer

**Symptoms**:
- Turtle not appearing in control
- "No control computer found"
- Connection timeouts

**Solutions**:

1. **Verify modems**:
   ```lua
   -- On both devices:
   peripheral.find("modem")
   ```

2. **Check protocol**:
   ```lua
   -- Should be "ULTIMATE_MINER_V2"
   /turtle/main.lua network info
   ```

3. **Test connection**:
   ```lua
   -- On turtle:
   /turtle/main.lua network discover
   
   -- On control:
   /control/main.lua fleet discover
   ```

4. **Restart network**:
   ```lua
   -- Both devices:
   /turtle/main.lua network restart
   /control/main.lua network restart
   ```

### High Network Lag

**Symptoms**:
- Delayed command execution
- Status updates slow
- Heartbeat warnings

**Solutions**:

1. **Enable optimization**:
   ```lua
   /turtle/main.lua network optimize on
   ```

2. **Reduce update frequency**:
   ```lua
   -- In config:
   heartbeat_interval = 10  -- seconds
   status_batch_interval = 15
   ```

3. **Check modem type**:
   - Use ender modems for long range
   - Reduce wireless modem range

### Lost Connection During Operation

**Symptoms**:
- Turtle continues but no updates
- Control shows offline
- Commands not received

**Solutions**:

1. **Auto-recovery**:
   - Turtle continues operation
   - Reconnects automatically
   - Updates resume when online

2. **Force reconnect**:
   ```lua
   /turtle/main.lua network reconnect
   ```

3. **Check for interference**:
   - Other CC programs using network
   - Too many devices on channel
   - Server network limits

## GPS Issues

### GPS Not Available

**Symptoms**:
- "GPS not available" error
- Position unknown
- Manual mode only

**Solutions**:

1. **Build GPS network**:
   - Need 4+ satellites
   - Place at Y=255
   - See GPS setup guide

2. **Verify satellites**:
   ```lua
   -- On satellite:
   gps host
   ```

3. **Test from turtle**:
   ```lua
   gps locate
   ```

### GPS Position Wrong

**Symptoms**:
- Coordinates don't match reality
- Turtle mines wrong location
- Position jumps around

**Solutions**:

1. **Check satellite coordinates**:
   - Verify each satellite has correct position
   - Ensure proper spacing

2. **Minimum satellites**:
   ```lua
   -- Need 4+ satellites in range
   /turtle/main.lua gps satellites
   ```

3. **Manual override**:
   ```lua
   /turtle/main.lua gps trust false
   -- Uses relative positioning
   ```

## Memory and Performance

### Out of Memory Errors

**Symptoms**:
- "Out of memory" crashes
- Turtle freezes
- Slow operation

**Solutions**:

1. **Enable low memory mode**:
   ```lua
   /turtle/main.lua performance low
   ```

2. **Clear caches**:
   ```lua
   /turtle/main.lua memory clear all
   ```

3. **Reduce history sizes**:
   ```lua
   -- In config:
   path_history_size = 250
   operation_history_size = 50
   ```

4. **Monitor memory**:
   ```lua
   /turtle/main.lua memory stats
   ```

### Poor Mining Performance

**Symptoms**:
- Low blocks/minute
- Inefficient patterns
- High fuel usage

**Solutions**:

1. **Run optimization analysis**:
   ```lua
   /turtle/main.lua analyze performance
   ```

2. **Switch patterns**:
   - Try different mining pattern
   - Use adaptive mining
   - Optimize for ore type

3. **Check for issues**:
   ```lua
   /turtle/main.lua diagnostics performance
   ```

## Storage Problems

### Can't Find Storage

**Symptoms**:
- "No storage found" error
- Items not deposited
- Turtle holds items

**Solutions**:

1. **Verify storage placement**:
   - Must be adjacent to turtle
   - Check all 6 directions
   - Ensure it's a valid container

2. **Test storage**:
   ```lua
   /turtle/main.lua storage scan
   ```

3. **Set storage location**:
   ```lua
   /turtle/main.lua storage mark
   ```

### Storage Full

**Symptoms**:
- Items dropped on ground
- Mining stops
- "Storage full" warnings

**Solutions**:

1. **Add more storage**:
   - Connect more chests
   - Use larger containers
   - Add overflow storage

2. **Configure item filtering**:
   ```lua
   -- Only store valuable items
   /turtle/main.lua config set store_only "ore,valuable"
   ```

3. **Enable auto-drop**:
   ```lua
   /turtle/main.lua config set auto_drop true
   ```

## Error Messages

### Common Error Codes

| Error Code | Meaning | Solution |
|------------|---------|----------|
| 100 | Movement blocked | Clear obstruction |
| 101 | No fuel | Add fuel to turtle |
| 102 | Position unsafe | Check boundaries |
| 200 | Cannot mine | Check tool/permissions |
| 201 | Tool broken | Tool might be missing |
| 202 | Inventory full | Empty inventory |
| 300 | Connection failed | Check network |
| 301 | Timeout | Retry operation |
| 400 | Storage full | Empty storage |
| 401 | No storage found | Place storage |
| 500 | Hazard detected | Check for lava/water |
| 501 | Emergency stop | Manual intervention |

### Interpreting Stack Traces

```lua
-- Example error:
mining.lua:142: attempt to index nil value
```

**Reading the error**:
- File: `mining.lua`
- Line: `142`
- Problem: Trying to use nil as table

**Common causes**:
- Missing initialization
- Failed API call
- Corrupted state

**Debug steps**:
1. Note the file and line
2. Check recent changes
3. Verify dependencies
4. Test in isolation

## Recovery Procedures

### Turtle Crash Recovery

1. **Automatic recovery**:
   - Turtle saves state every 30 seconds
   - Resumes operation on restart
   - Position recovered from GPS/state

2. **Manual recovery**:
   ```lua
   -- Start in recovery mode
   /turtle/main.lua --recover
   ```

3. **State repair**:
   ```lua
   /turtle/main.lua state repair
   ```

### Corrupted Data Recovery

1. **Automatic**:
   - Triple backup system
   - Checksum validation
   - Auto-restore from backup

2. **Manual restore**:
   ```lua
   -- List backups
   ls /turtle/state/backups/
   
   -- Restore specific backup
   /turtle/main.lua state restore <backup_file>
   ```

3. **Reset to defaults**:
   ```lua
   /turtle/main.lua reset --keep-config
   ```

### Network Recovery

1. **Connection lost**:
   - Auto-reconnect every 30 seconds
   - Operations continue offline
   - Updates resume when connected

2. **Force recovery**:
   ```lua
   /turtle/main.lua network reset
   ```

### Position Recovery

1. **Try GPS**:
   ```lua
   /turtle/main.lua position gps
   ```

2. **Use landmarks**:
   ```lua
   /turtle/main.lua position landmark
   ```

3. **Manual set**:
   ```lua
   /turtle/main.lua position set <x> <y> <z>
   ```

## Advanced Debugging

### Enable Debug Mode

```lua
/turtle/main.lua debug on
```

Shows:
- Detailed operation logs
- Network messages
- State changes
- Performance metrics

### Log Analysis

```lua
-- View recent logs
cat /logs/turtle.log

-- Filter for errors
grep ERROR /logs/turtle.log

-- Watch real-time
tail -f /logs/turtle.log
```

### Performance Profiling

```lua
-- Start profiler
/turtle/main.lua profile start

-- Run operations...

-- View results
/turtle/main.lua profile report
```

### Network Debugging

```lua
-- Monitor all messages
/turtle/main.lua network monitor

-- Test specific message
/turtle/main.lua network test <message_type>
```

## Frequently Asked Questions

### Q: Why does my turtle stop mining randomly?

**A**: Common causes:
- Fuel ran out
- Inventory full
- Hit boundary
- Found hazard
- Lost connection

Check: `/turtle/main.lua status`

### Q: How do I make mining faster?

**A**: 
1. Use efficient patterns (strip/branch)
2. Enable performance mode
3. Optimize inventory management
4. Use ender chest
5. Reduce safety checks

### Q: Can I run multiple control computers?

**A**: Yes, but:
- Only one active controller per turtle
- Can have observer controls
- Coordinate task assignment

### Q: Why doesn't GPS work underground?

**A**: GPS needs line of sight to satellites. Solutions:
- Build underground repeaters
- Use manual positioning
- Rely on relative positioning

### Q: How do I recover a "ghost" turtle?

**A**: Ghost state recovery:
```lua
-- On turtle
/turtle/main.lua ghost recover

-- From control
/control/main.lua turtle <id> recover
```

### Q: Can I modify mining patterns?

**A**: Yes:
- Edit pattern files in `/turtle/patterns/`
- Create custom patterns
- Use pattern API

### Q: How do I handle chunk unloading?

**A**: 
1. Use chunk loaders
2. Set smaller operation areas
3. Enable boundary detection
4. Use return-home on unload

### Q: What's the maximum fleet size?

**A**: Recommended: 20 turtles per control
- Can handle more with optimization
- Depends on network quality
- Consider multiple control stations

## Getting Further Help

1. **Check documentation**:
   - User Manual: `/docs/user_manual.md`
   - API Reference: `/docs/api_reference.md`

2. **Community resources**:
   - GitHub Issues
   - Discord server
   - Forum thread

3. **Reporting bugs**:
   Include:
   - Version number
   - Error messages
   - Steps to reproduce
   - Diagnostic output

Remember: Most issues have automatic recovery. Let the system try to self-heal before manual intervention.