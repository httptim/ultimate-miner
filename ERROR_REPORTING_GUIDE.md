# Ultimate Miner Error Reporting Guide

## How Error Reporting Works

The Ultimate Miner system now includes comprehensive error reporting that:
1. Catches all crashes and errors
2. Saves them to a log file
3. Uploads to pastebin automatically
4. Provides you with a code to share

## When You See an Error

### During Normal Operation
If the program crashes, you'll see:
```
=== CRITICAL ERROR ===
Error: [error message]

Creating error report...

=== ERROR REPORT UPLOADED ===
Pastebin Code: ABC123
URL: https://pastebin.com/ABC123

Please include this code when reporting!
```

**Important**: Write down or screenshot the pastebin code!

### If Upload Fails
If pastebin upload fails, errors are saved locally:
- Turtle crashes: `/ultimate_miner_errors.log` or `/ultimate_miner_crash.log`
- Control crashes: `/ultimate_miner_errors.log` or `/control_crash.log`

## Manual Error Reporting

### From Main Menu
**Turtle**: Select option 6 - "Error Report"
**Control Computer**: Select "Error Report" from dashboard

### Using Commands
```lua
-- Test if error reporting works
lua test_crash.lua

-- View error log
edit /ultimate_miner_errors.log

-- Create manual report
lua test_error_reporting.lua
```

## What Gets Logged

Each error report includes:
- Error message and type
- Stack trace (if available)
- Time and date
- Session ID
- Device type (turtle/computer)
- Context information

## Reporting Issues

When reporting at https://github.com/httptim/ultimate-miner/issues, include:

1. **The pastebin code** (most important!)
2. What you were doing when it crashed
3. Your Minecraft version
4. Your CC:Tweaked version
5. Any other mods installed

## Common Issues Fixed

### "attempt to index local 'saved_data' (a boolean value)"
This has been fixed in the latest version. The monitoring module now properly handles State.loadFile returns.

### "module not found" on startup
Fixed by moving error handler initialization after module paths are set up.

## Testing Error Reporting

To verify error reporting is working:
```
lua test_crash.lua
```

This will:
1. Create a test error
2. Try to upload to pastebin
3. Show you if everything is working

## Privacy Note

Error reports only contain:
- Technical error information
- No personal data
- No world coordinates
- No player names

Pastebin links are unlisted and expire after 1 week.