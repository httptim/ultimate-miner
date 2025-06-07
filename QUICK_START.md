# Ultimate Miner - Quick Start Guide

Get mining in 5 minutes! This guide assumes you have CC:Tweaked installed.

## Fastest Setup (No GPS)

### On Your Mining Turtle:

1. **Place** a Mining Turtle with Wireless Modem attached
2. **Add Fuel** - Put coal in any slot
3. **Install** - Type this command:
   ```
   wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua
   ```
4. Select `1` (Install turtle components)
5. Select `y` when asked about startup file

### Start Mining:

1. Type: `turtle/main.lua`
2. Press `1` (Start Mining)
3. Press `1` (Strip Mining)
4. Enter `1` for strips, `16` for length
5. Watch it mine!

**Note**: Without GPS, the turtle uses relative positioning. Set up GPS for better features.

---

## Recommended Setup (With GPS)

### 1. Quick GPS Setup (5 minutes)

Build this at Y=254:
```
    N
    |
W---+---E
    |
    S

Place computers at N,S,E,W (5+ blocks from center)
Attach wireless modems to each
```

On each GPS computer:
```
edit startup.lua
```
Type (replace with actual coords):
```lua
shell.run("gps", "host", X, Y, Z)
```
Save (Ctrl+S), Exit (Ctrl+E), then:
```
reboot
```

### 2. Turtle Setup (2 minutes)

Same as above, but now the turtle will use GPS positioning!

### 3. Control Computer (Optional, 3 minutes)

On an Advanced Computer with Wireless Modem:
```
wget run https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua
```
Select `2` (Control computer)

Now you can control multiple turtles from one location!

---

## First Mining Tips

1. **Place storage chests** at the turtle's starting position
2. **Add torches** to slot 15 for auto-lighting
3. **Start with small operations** (1 strip, 16 length)
4. **Keep fuel handy** - turtle auto-refuels from inventory

## Commands Cheat Sheet

### On Turtle:
- `1` - Start Mining (choose patterns)
- `3` - Test Movement (verify GPS)
- `5` - Network Mode (connect to control)

### On Control Computer:
- `F` - Fleet Overview
- `C` - Send Commands
- `T` - Create Tasks
- `E` - Emergency Stop All

## Troubleshooting

**"No fuel"** → Put coal in turtle  
**"Could not determine position"** → Check GPS setup  
**"Cannot move"** → Check for bedrock or protected areas  

## Want More?

See `SETUP_GUIDE.md` for the complete guide with all features!