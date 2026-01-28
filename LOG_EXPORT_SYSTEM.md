# Log Export System

This document describes the new log export system integrated into YouGame.

## Overview

The log export system allows developers to capture and export specific types of debug logs to help diagnose issues in the game. The system is extensible and can be easily expanded to support new log types in the future.

## Log Types

### 1. Sun Lighting Issue Logs
**Purpose:** Captures logs related to the sun degree lighting problem where the game stays dark even when sun degree is > 80°, then at 180° suddenly gets bright for very short and then dark again.

**What it logs:**
- Sun position in degrees
- Light rotation angle
- Directional light energy level
- Ambient brightness (calculated from ambient light color and energy)
- Total brightness (directional + ambient)
- Current time in the day/night cycle
- Day count
- Ambient light source type
- Environment background mode (sky enabled/disabled)
- Animation states (sunrise, sunset, night)

**Logged during:**
- Game start (initial environment state)
- Every 10 seconds during normal day progression (to capture all lighting states)
- When sun position > 80° (more frequently for critical angles)
- During sunrise animation
- During sunset animation
- When entering night mode
- When sunrise completes
- On app pause/resume events

### 2. Sleep State Issue Logs
**Purpose:** Captures logs related to the problematic state after loading a save game where the player was in the sleeping phase, and when the app is paused/resumed.

**What it logs:**
- is_locked_out status
- lockout_end_time (Unix timestamp)
- current_unix_time
- time_until_lockout_end
- current_time in the day cycle
- day_count
- night_start_time
- Animation states (night, sunrise, sunset, locked)
- Player position, rotation, health, and air when loading save
- App lifecycle events (pause/resume)

**Logged during:**
- Game start (if locked out or normal day start)
- When save game is loaded (in SaveGameManager)
- When day/night cycle loads state from SaveGameManager
- When player state is loaded
- When lockout expires
- When entering sleep mode (sunset complete)
- When app is paused (going to background)
- When app is resumed (coming from background)
- During sunrise completion

### 3. Error Logs
**Purpose:** Captures error messages and exceptions that occur during gameplay.

**What it logs:**
- Error messages from LogExportManager.add_error()
- Runtime errors and exceptions
- Failed operations

**Logged during:**
- When errors are explicitly logged
- When operations fail

## How to Use

### In-Game Export

#### Export Individual Logs
1. Open the debug log overlay (click the 📋 button in the top-left corner)
2. Click the ☀ button to export Sun Lighting Issue logs
3. Click the 🌙 button to export Sleep State Issue logs
4. Logs are saved to `user://logs/` directory with timestamped filenames

#### Export All Logs to ZIP (Recommended)
1. Click the 📦 button in the top-left corner
2. A ZIP file will be created containing:
   - `0_metadata.txt` - System information and summary
   - `1_sun_lighting_issue.log` - Brightness/sun problem logs
   - `2_sleep_state_issue.log` - Sleep state debugging logs
   - `3_error_logs.log` - Error messages and exceptions
3. ZIP file is saved to `user://logs/` directory with timestamped filename

### Programmatic Usage

```gdscript
# Add a log entry
LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, "Your log message here")
LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, "Your log message here")

# Add an error log entry
LogExportManager.add_error("Error message here")

# Export individual logs to file
var filepath = LogExportManager.export_logs(LogExportManager.LogType.SUN_LIGHTING_ISSUE)

# Export all logs to ZIP
var zip_path = LogExportManager.export_all_logs_as_zip()

# Get log count
var count = LogExportManager.get_log_count(LogExportManager.LogType.SUN_LIGHTING_ISSUE)

# Clear logs
LogExportManager.clear_logs(LogExportManager.LogType.SUN_LIGHTING_ISSUE)

# Get all logs as array
var logs = LogExportManager.get_logs(LogExportManager.LogType.SUN_LIGHTING_ISSUE)
```

## Adding New Log Types

To add a new log type:

1. Add a new enum value to `LogType` in `scripts/log_export_manager.gd`:
```gdscript
enum LogType {
    SUN_LIGHTING_ISSUE,
    SLEEP_STATE_ISSUE,
    GENERAL_DEBUG,
    YOUR_NEW_TYPE  # Add here
}
```

2. Add storage for the new type:
```gdscript
var your_new_logs: Array[String] = []
```

3. Update all match statements in `log_export_manager.gd` to handle the new type

4. (Optional) Add a UI button in `debug_log_overlay.gd` to export the new log type

## File Format

Exported log files include:
- Header with metadata (log type, export time, total entries, game version)
- Timestamped log entries
- Plain text format for easy reading

Example filename: `sun_lighting_issue_2026-01-22T19-16-36.log`

## Android Widget Integration

The home screen widget can be integrated into the release APK build:
- Build the widget AAR using `./android/plugins/savegame_widget/build_widget.sh`
- Widget displays save game information (day count, health, position, etc.)
- Widget updates automatically when the game is saved
- See `android/plugins/savegame_widget/README.md` for build instructions

## Export Configuration

The widget plugin is ready to be enabled in export presets:
- Add to `plugins/enabled` array in `export_presets.cfg` after building the AAR
- Uses standard (non-Gradle) APK export - no Android build template required
- Widget AAR must exist before exporting: `android/plugins/savegame_widget/savegame_widget.aar`
