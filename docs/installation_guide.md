# Ultimate Miner Installation Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Manual Installation](#manual-installation)
4. [Installation Options](#installation-options)
5. [Post-Installation Setup](#post-installation-setup)
6. [Network Configuration](#network-configuration)
7. [GPS Setup](#gps-setup)
8. [Verification](#verification)
9. [Updating](#updating)
10. [Uninstallation](#uninstallation)
11. [Troubleshooting Installation](#troubleshooting-installation)

## Prerequisites

### Required
- Minecraft 1.21.1
- CC:Tweaked mod (latest version recommended)
- Mining Turtle (crafted with turtle + diamond pickaxe)
- Fuel for the turtle (coal, lava bucket, etc.)

### Recommended
- Advanced Computer (for control station)
- Wireless Modem or Ender Modem
- GPS satellite network (for precise positioning)
- Chunk loader (for large-scale operations)

### System Requirements
- **Disk Space**: ~500KB per device
- **Memory**: Standard CC:Tweaked limits apply
- **Network**: Port 65535 (default rednet)

## Quick Installation

### Method 1: Web Installer (Recommended)

1. **Place your turtle or computer** in the world

2. **Attach a modem** (if using network features)
   - Right-click with modem on turtle/computer
   - Ender modems recommended for long range

3. **Open the terminal** (right-click the computer/turtle)

4. **Download and run the installer**:
   ```bash
   wget https://github.com/httptim/ultimate-miner/raw/main/installer.lua installer
   installer
   ```

5. **Follow the on-screen prompts**:
   - Choose installation type
   - Confirm installation path
   - Create startup file (optional)

### Method 2: Pastebin Installer

If GitHub is blocked or unavailable:

1. **Get the pastebin code** from the project page

2. **Run the pastebin installer**:
   ```bash
   pastebin run [PASTEBIN_CODE]
   ```

3. **Follow the same prompts** as Method 1

## Manual Installation

### Step 1: Download Files

#### Option A: Using Git (if available)
```bash
git clone https://github.com/httptim/ultimate-miner.git
```

#### Option B: Download ZIP
1. Visit https://github.com/httptim/ultimate-miner
2. Click "Code" → "Download ZIP"
3. Extract to your computer

### Step 2: Transfer Files to Minecraft

#### For Single Player:
1. Navigate to your Minecraft instance folder
2. Find `saves/[YourWorld]/computercraft/computer/[ID]/`
3. Copy the appropriate folders:
   - For turtles: `turtle/` and `shared/`
   - For computers: `control/` and `shared/`

#### For Multiplayer:
1. Use an in-game disk drive:
   ```bash
   -- On external computer with files
   cp -r /ultimate-miner/* /disk/
   
   -- On target turtle/computer
   cp -r /disk/* /
   ```

2. Or use `wget` for individual files:
   ```bash
   wget [URL] [destination]
   ```

### Step 3: Set Permissions (if needed)

Ensure all Lua files are readable:
```bash
-- No specific permissions needed in CC:Tweaked
-- Files are automatically executable
```

## Installation Options

### Full Installation (Both Components)

Installs both turtle and control computer components:

```bash
installer
-- Select option 2: "Install both turtle and control components"
```

**Use when**: Setting up a complete mining operation with central control

### Turtle-Only Installation

Installs only the mining turtle components:

```bash
installer
-- Select option 1: "Install turtle components"
```

**Use when**: 
- Running standalone mining operations
- Adding turtles to existing setup
- Testing without control computer

### Control-Only Installation

Installs only the control computer components:

```bash
installer  
-- Select option 1: "Install computer components"
```

**Use when**:
- Setting up additional control stations
- Replacing a control computer
- Creating backup control center

### Custom Installation

Choose specific components to install:

```bash
installer
-- Select option 3: "Install specific component"
```

Options include:
- Turtle components only
- Control components only  
- Shared libraries only
- Individual modules

## Post-Installation Setup

### For Turtles

1. **Add Fuel**:
   ```lua
   -- Place fuel in any slot
   refuel all
   -- Or use specific slot
   refuel 1
   ```

2. **Set Home Position**:
   ```lua
   /turtle/main.lua
   -- Select "Configure Settings"
   -- Choose "Set Home Position"
   ```

3. **Configure Safety Radius**:
   ```lua
   -- In settings menu
   -- Set maximum distance from home
   -- Default: 1000 blocks
   ```

4. **Test Movement**:
   ```lua
   -- From main menu
   -- Select "Test Movement"
   -- Run basic movement test
   ```

### For Control Computers

1. **Verify Modem**:
   ```lua
   peripheral.find("modem")
   -- Should return modem side
   ```

2. **Open Rednet**:
   ```lua
   -- Automatic on startup
   -- Or manually:
   rednet.open("back")  -- or appropriate side
   ```

3. **Set Computer Label**:
   ```lua
   label set "Mining Control"
   ```

## Network Configuration

### Wireless Setup

1. **Attach Wireless Modem**:
   - Craft: 8 stone + 1 ender pearl
   - Right-click on computer/turtle

2. **Verify Connection**:
   ```lua
   rednet.open("right")  -- or appropriate side
   rednet.broadcast("test")
   ```

3. **Configure Protocol**:
   - Default: "ULTIMATE_MINER_V2"
   - No manual configuration needed

### Ender Modem Setup

1. **Attach Ender Modem**:
   - Craft: 8 end stone + 1 eye of ender
   - Unlimited range across dimensions

2. **Priority Configuration**:
   - System prefers ender modems automatically
   - No additional setup required

### Wired Network

1. **Connect with Networking Cable**:
   - Place cable between devices
   - Attach wired modems to each device

2. **Activate Modems**:
   - Right-click each modem (red light = active)

3. **Configure**:
   ```lua
   -- Automatic detection
   -- Works alongside wireless
   ```

## GPS Setup

### Creating GPS Satellites

1. **Build GPS Array**:
   - Place 4+ computers at Y=255
   - Arrange in cardinal directions
   - Space at least 100 blocks apart

2. **Install GPS Host**:
   ```lua
   -- On each satellite
   edit startup
   -- Add:
   shell.run("gps", "host", x, y, z)
   -- Replace x,y,z with satellite coordinates
   ```

3. **Attach Modems**:
   - Wireless modem on each satellite
   - Open with: `rednet.open("top")`

### Testing GPS

1. **On Turtle**:
   ```lua
   gps locate
   -- Should return coordinates
   ```

2. **Calibrate**:
   ```lua
   /turtle/main.lua
   -- Test Movement → GPS Calibration
   ```

3. **Manual Fallback**:
   ```lua
   -- If GPS fails
   /turtle/main.lua gps manual 100 64 100
   ```

## Verification

### Verify Turtle Installation

1. **Check Files**:
   ```lua
   ls /turtle/
   -- Should show: main.lua, modules/, patterns/
   
   ls /shared/
   -- Should show: constants.lua, module_loader.lua
   ```

2. **Run Diagnostics**:
   ```lua
   /turtle/main.lua diagnostics all
   ```

3. **Test Mining**:
   ```lua
   /turtle/main.lua
   -- Select "Start Mining"
   -- Choose "Test Pattern"
   ```

### Verify Control Installation

1. **Check Files**:
   ```lua
   ls /control/
   -- Should show: main.lua, modules/, screens/, ui/
   ```

2. **Start Control**:
   ```lua
   /control/main.lua
   -- Should show dashboard
   ```

3. **Check Network**:
   ```lua
   -- Should auto-detect turtles
   -- Status: "Waiting for turtles..."
   ```

### Verify Communication

1. **Start Both Systems**:
   - Run turtle program
   - Run control program

2. **Check Connection**:
   - Turtle should appear in control dashboard
   - Status should update regularly

3. **Test Commands**:
   - Send simple command from control
   - Verify turtle responds

## Updating

### Automatic Update

1. **Run Installer Again**:
   ```lua
   installer
   -- Select "Update existing installation"
   ```

2. **Preserve Settings**:
   - Configuration is preserved
   - State data is maintained
   - Custom patterns kept

### Manual Update

1. **Backup Current Installation**:
   ```lua
   cp -r /turtle /turtle_backup
   cp -r /control /control_backup
   ```

2. **Download New Version**:
   - Follow manual installation steps
   - Overwrite existing files

3. **Restore Configuration**:
   ```lua
   cp /turtle_backup/config.json /turtle/
   ```

### Version Migration

The system handles version migrations automatically:
- Data structures updated on first run
- Backups created before migration
- Rollback available if needed

## Uninstallation

### Complete Removal

1. **Run Installer**:
   ```lua
   installer
   -- Select option 4: "Uninstall"
   ```

2. **Confirm Removal**:
   - All Ultimate Miner files removed
   - Startup files cleaned
   - Configuration deleted

### Partial Removal

1. **Remove Specific Components**:
   ```lua
   rm -r /turtle
   -- or
   rm -r /control
   ```

2. **Clean Startup**:
   ```lua
   edit startup
   -- Remove Ultimate Miner lines
   ```

### Preserve Data

1. **Backup Before Removal**:
   ```lua
   cp -r /turtle/state /backup/
   cp /turtle/config.json /backup/
   ```

2. **Export Statistics**:
   ```lua
   /turtle/main.lua export stats
   ```

## Troubleshooting Installation

### Common Issues

#### "HTTP API not enabled"
**Solution**:
1. Exit Minecraft
2. Edit `config/computercraft.cfg`
3. Set `B:http_enable=true`
4. Restart Minecraft

#### "File not found" errors
**Solution**:
1. Verify installation completed
2. Check file paths are correct
3. Re-run installer
4. Use manual installation

#### "Out of disk space"
**Solution**:
1. CC:Tweaked disk space is limited
2. Remove unnecessary files
3. Use external disk drive
4. Increase config limit

#### Network not connecting
**Solution**:
1. Verify modem attached
2. Check both devices have modems
3. Ensure modems are open
4. Verify protocol matches

#### GPS not working
**Solution**:
1. Check satellite positions
2. Verify satellites running
3. Test with `gps locate`
4. Use manual position

### Installation Logs

Check installation logs:
```lua
-- View installer log
cat /install.log

-- View error log
cat /error.log
```

### Getting Help

1. **Check Documentation**:
   - `/docs/troubleshooting.md`
   - `/docs/user_manual.md`

2. **Run Diagnostics**:
   ```lua
   /turtle/main.lua diagnostics system
   ```

3. **Report Issues**:
   - GitHub: https://github.com/httptim/ultimate-miner/issues
   - Include version and error messages

## Best Practices

### Installation
1. Always backup existing setups
2. Test in creative mode first
3. Install during low-activity times
4. Verify prerequisites before starting

### Configuration
1. Document your settings
2. Use meaningful computer labels
3. Standardize modem placement
4. Plan GPS network layout

### Maintenance
1. Regular backups of state data
2. Monitor disk usage
3. Update during downtime
4. Test updates on single turtle first

## Conclusion

Ultimate Miner is now installed and ready for use. Refer to the User Manual for operation instructions and the API Reference for advanced usage.

For additional support, consult the troubleshooting guide or open an issue on GitHub.