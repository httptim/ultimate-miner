# Ultimate Miner v3.0.0 - Complete Setup Guide

This guide will walk you through setting up the Ultimate Miner system in your Minecraft world with CC:Tweaked.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [GPS Tower Setup](#gps-tower-setup)
3. [Turtle Setup](#turtle-setup)
4. [Control Computer Setup](#control-computer-setup)
5. [First Mining Operation](#first-mining-operation)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Items
- **For GPS Network:**
  - 4 Computers (any type)
  - 4 Wireless Modems (or Ender Modems for infinite range)
  - Building blocks to reach Y=254

- **For Mining Operations:**
  - 1+ Mining Turtles (not regular turtles - they need to be able to dig)
  - 1 Wireless Modem per turtle (or Ender Modem)
  - Fuel for turtles (coal, charcoal, lava buckets, etc.)
  - Torches (optional, for lit mining)
  - Chests for storage

- **For Control Center:**
  - 1 Advanced Computer (recommended) or Computer
  - 1 Wireless Modem (or Ender Modem)
  - (Optional) Monitors for fleet display

### Mod Requirements
- Minecraft 1.21.1
- CC:Tweaked mod (latest version for 1.21.1)

## GPS Tower Setup

The GPS system is **required** for the Ultimate Miner to track turtle positions accurately.

### Step 1: Build GPS Towers

You need exactly 4 GPS computers placed in a specific pattern:

1. **Choose a central location** in your base
2. **Build up to Y=254** (max build height gives best range)
3. **Place 4 computers** in this pattern:
   ```
   North (+Z)
        C
        |
   C----+----C  
        |
        C
   South (-Z)
   
   (C = Computer with Wireless Modem)
   ```
   - Each computer should be at least 4 blocks away from the center
   - All at the same Y level (254 recommended)
   - Attach a wireless modem to each computer

### Step 2: Program GPS Computers

On **each** GPS computer:

1. Open the computer and type:
   ```
   edit startup.lua
   ```

2. Enter this code (replace X, Y, Z with the actual coordinates):
   ```lua
   shell.run("gps", "host", X, Y, Z)
   ```
   
   To get coordinates:
   - Press F3 in Minecraft
   - Look at "XYZ:" line
   - Use the Block position, not the player position

3. Save and exit (Ctrl+S, Ctrl+E)

4. Reboot the computer:
   ```
   reboot
   ```

5. You should see: `GPS position is X, Y, Z`

### Step 3: Test GPS Network

On any computer with a wireless modem:
```
gps locate
```

You should see coordinates. If you see "Could not determine position", check your GPS setup.

## Turtle Setup

### Step 1: Prepare the Turtle

1. **Place a Mining Turtle** (must be a mining turtle, not regular)
2. **Attach a Wireless Modem** (right-click with modem)
3. **Add Fuel** - Right-click to open GUI and place coal/charcoal in any slot
4. **Add Torches** (optional) - Place in slot 15 for auto-lighting

### Step 2: Install Ultimate Miner on Turtle

1. Open the turtle (right-click)
2. Type this command:
   ```
   wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua
   ```

3. When prompted, select:
   - `1` for "Install turtle components"

4. Wait for installation to complete

5. When asked "Create startup file?", type `y`

### Step 3: Initial Turtle Configuration

1. The turtle should automatically start the Ultimate Miner program
2. If not, type:
   ```
   turtle/main.lua
   ```

3. You'll see the main menu:
   ```
   === Ultimate Miner - Main Menu ===
   
   1. Start Mining
   2. Configure Settings  
   3. Test Movement
   4. View Statistics
   5. Network Control Mode
   6. Exit
   ```

4. **First Time Setup:**
   - Select `3` (Test Movement)
   - Select `3` (Test GPS location)
   - If GPS works, you'll see your position
   - If not, check your GPS towers

## Control Computer Setup

### Step 1: Set Up Control Computer

1. **Place an Advanced Computer** (regular works but Advanced recommended)
2. **Attach a Wireless Modem**
3. **(Optional)** Attach monitors on any side for fleet display

### Step 2: Install Control Software

1. Open the computer
2. Type:
   ```
   wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua
   ```

3. Select option `2` for "Install control computer components"

4. Create startup file when prompted

### Step 3: Start Control Center

1. Run the control program:
   ```
   control/main.lua
   ```

2. You'll see the dashboard:
   ```
   === Ultimate Miner Control ===
   Fleet Status: 0 turtles connected
   ```

## First Mining Operation

### Option A: Direct Turtle Control

1. On the turtle, select `1` (Start Mining)
2. Choose a pattern:
   - `1` - Strip Mining (recommended for beginners)
   - `2` - Single Block Test
   - `3` - 3x3 Tunnel
   
3. For Strip Mining:
   - Number of strips: `1` (start small)
   - Strip length: `16`

4. The turtle will begin mining!

### Option B: Fleet Control (Recommended)

1. **On the Turtle:**
   - Select `5` (Network Control Mode)
   - The turtle will connect to the control network

2. **On the Control Computer:**
   - You should see "1 turtle connected"
   - Use the menu to:
     - View fleet status
     - Send mining commands
     - Monitor progress

### Basic Fleet Commands

From the control computer dashboard:

1. **F** - Fleet Overview (see all turtles)
2. **C** - Fleet Commands 
3. **T** - Task Assignment
4. **S** - Settings

#### Sending a Mining Command:
1. Press **C** for Fleet Commands
2. Select a mining pattern
3. Choose target turtles (or all)
4. Enter parameters
5. Press Enter to execute

## Storage Setup

### Recommended Storage Configuration

Place chests around the turtle's home position:
```
  C
C T C
  C

T = Turtle home position
C = Chests
```

The turtle will automatically deposit items when inventory is full.

## Safety Features

The Ultimate Miner includes automatic safety features:

- **Fuel Management**: Returns home before running out
- **Inventory Management**: Returns to deposit when full
- **Hazard Detection**: Handles lava, water, gravel
- **Position Recovery**: Can recover from restarts
- **Claim Protection**: Respects server claims

## Advanced Features

### Resource Targeting
From the control computer:
1. Press **T** for Task Assignment
2. Select "Resource Targeting"
3. Choose ore type (diamond, iron, etc.)
4. Set quantity
5. Assign to turtles

### Area Mining
1. Define boundaries (X, Z coordinates)
2. System automatically optimizes Y level
3. Multiple turtles coordinate to avoid overlap

### Monitor Display
If you attached monitors to the control computer:
- Automatically shows fleet overview
- Real-time status updates
- Press **M** to cycle display modes

## Troubleshooting

### "Could not determine position"
- Check GPS towers are running
- Ensure wireless modems are attached
- Verify GPS coordinates are correct

### "No fuel"
- Add coal/charcoal to turtle
- Configure auto-refuel in settings

### Turtle Not Moving
1. Check fuel level
2. Verify area is not protected
3. Ensure it's a mining turtle
4. Check for bedrock/unbreakable blocks

### Can't Connect to Control
- Verify wireless modems on both devices
- Check if using same protocol (ULTIMATE_MINER_V2)
- Ensure control computer is running

### Performance Issues
- Limit fleet to 20 turtles
- Use ender modems for long range
- Reduce heartbeat frequency in settings

### "Syntax error" on startup
If you see errors like "syntax error near 'end'" or "module not found":
1. The installer may have downloaded a version with syntax errors
2. Re-run the installer to get the fixed version:
   ```
   rm startup.lua
   wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua
   ```
3. Select your device type and install again

### Installer loops after creating startup
This is a known issue that has been fixed. The installer now properly reboots after successful installation.

### Reporting Errors
If you encounter errors that you cannot see completely:

**On Turtle:**
1. Select option `6` from the main menu (Error Report)
2. The system will automatically upload errors to pastebin
3. You'll receive a pastebin code to share when reporting issues

**On Control Computer:**
1. Select "Error Report" from the dashboard
2. Follow the same process as above

**Alternative Methods:**
- Error logs are saved to `/ultimate_miner_errors.log`
- Pastebin codes are saved to `/pastebin_info.txt`
- You can manually run: `lua test_error_reporting.lua`

When reporting issues at https://github.com/httptim/ultimate-miner/issues, include:
- The pastebin code
- What you were doing when the error occurred
- Your Minecraft and CC:Tweaked versions

## Tips for Success

1. **Start Small**: Test with 1 turtle before scaling up
2. **Keep Fuel Stocked**: Always have extra fuel in storage
3. **Use Waypoints**: Set home position near storage
4. **Monitor First Runs**: Watch for any issues
5. **Use Patterns**: Strip mining is most efficient for ores
6. **Backup Regularly**: The system auto-saves progress

## Need Help?

- Check `/docs/troubleshooting_guide.md` for detailed solutions
- Visit the GitHub repository for updates
- Report issues at: https://github.com/httptim/ultimate-miner/issues

Happy Mining! ⛏️