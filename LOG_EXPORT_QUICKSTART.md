# Quick Start Guide for Log Export System

## How to Use the Log Export Features

### Accessing the Debug Log Overlay

The debug log overlay is visible by default when the game starts. It shows a panel with recent debug messages in the top-left area of the screen.

### Button Layout (Top Left)

From left to right:
1. **📋 (Clipboard)** - Toggle the debug log panel visibility
2. **🗑 (Trash)** - Clear all current debug logs
3. **📄 (Document)** - Copy debug logs to clipboard
4. **☀ (Sun)** - Export Sun Lighting Issue logs to file
5. **🌙 (Moon)** - Export Sleep State Issue logs to file
6. **📦 (Package)** - Export ALL logs to a ZIP file (recommended)

### Exporting Sun Lighting Logs

1. Play the game and observe the lighting behavior
2. When you encounter the issue (stays dark at high sun angles, brief brightness at 180°):
   - Click the **☀ (Sun)** button
   - A confirmation message will appear in the debug log
   - The file path will be displayed (e.g., `user://logs/sun_lighting_issue_2026-01-22T19-16-36.log`)

3. Find the exported file:
   - **Windows**: `%APPDATA%\Godot\app_userdata\YouGame\logs\`
   - **Linux**: `~/.local/share/godot/app_userdata/YouGame/logs/`
   - **Android**: `/storage/emulated/0/Android/data/com.yougame.godot4/files/logs/`

### Exporting Sleep State Logs

1. Save the game while in the sleeping phase (night time, locked out)
2. Exit and reload the game
3. Click the **🌙 (Moon)** button to export sleep state logs
4. The logs will show all the sleep state data captured during the load process

### Exporting All Logs to ZIP (Recommended)

**This is the easiest way to export all debug information at once:**

1. Click the **📦 (Package)** button in the top-left corner
2. A ZIP file will be created containing:
   - `0_metadata.txt` - System information and log summary
   - `1_sun_lighting_issue.log` - Sun/brightness problem logs
   - `2_sleep_state_issue.log` - Sleep state debugging logs
   - `3_error_logs.log` - Error messages and exceptions
3. The ZIP file location will be displayed in the debug overlay
4. Find the file in the same location as individual logs (see above)

**The ZIP export is recommended because:**
- Contains all debugging information in one file
- Easy to share with developers
- Includes system information for better debugging
- Files are numbered for easy navigation

### Understanding the Log Files

#### Sun Lighting Issue Logs
Each entry contains:
- Timestamp
- Sun Position (in degrees, 0-360)
- Sun Angle (internal rotation)
- Light Energy (brightness level)
- Time Ratio (position in day cycle)
- Current Time (in seconds)

Example entry:
```
[2026-01-22 19:16:36] Sun Position: 85.23° | Sun Angle: -15.67° | Light Energy: 2.45 | Time Ratio: 0.35 | Current Time: 1890.45
```

#### Sleep State Issue Logs
Each entry contains:
- Timestamp
- is_locked_out (true/false)
- lockout_end_time (Unix timestamp)
- current_unix_time (Unix timestamp)
- time_until_end (seconds remaining)
- current_time (in-game time)
- day_count (which day)
- night_start_time (Unix timestamp)

Example entry:
```
[2026-01-22 19:16:36] LOAD - is_locked_out: true | lockout_end_time: 1737577136.00 | current_unix_time: 1737563136.00 | time_until_end: 14400.00 | current_time: 5400.00 | day_count: 3 | night_start_time: 1737562736.00
```

### Tips for Debugging

1. **Clear logs before testing**: Use the 🗑 button to start fresh
2. **Multiple exports**: You can export multiple times, each creates a new timestamped file
3. **Log storage**: Each log type stores up to 500 entries automatically
4. **Performance**: Logging only occurs at key moments, so it won't impact game performance

### For Developers

To add your own log entries programmatically:

```gdscript
# Sun lighting issue
LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, "Your debug message")

# Sleep state issue
LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, "Your debug message")

# Error logs (also automatically captured from push_error)
LogExportManager.add_error("Your error message")

# General debug
LogExportManager.add_log(LogExportManager.LogType.GENERAL_DEBUG, "Your debug message")

# Export all logs to a ZIP file
var zip_path = LogExportManager.export_all_logs_as_zip()
```

See `LOG_EXPORT_SYSTEM.md` for full API documentation.
