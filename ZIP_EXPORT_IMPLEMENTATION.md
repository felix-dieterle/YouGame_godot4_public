# ZIP Export Button Implementation - Summary

## Überblick (German Summary)

Ein neuer Export-Button wurde implementiert, der alle Debug-Logs in eine einzelne ZIP-Datei packt.

### Was wurde implementiert:

1. **Error Log Tracking** - Ein neues Log-System für Fehler wurde hinzugefügt
2. **ZIP Export Funktionalität** - Alle Logs werden in eine ZIP-Datei exportiert
3. **UI Button** - Ein 📦 Button wurde zur Debug-Oberfläche hinzugefügt

### The ZIP file contains:

1. `0_metadata.txt` - Systeminformationen und Zusammenfassung
2. `1_sun_lighting_issue.log` - Nützliche Daten zum Helligkeits/Sonnen Problem
3. `2_sleep_state_issue.log` - Log um rauszufinden warum Spiel nach erneuten Laden während Schlafenszeit in seltsamem Zustand ist
4. `3_error_logs.log` - Error logs
5. `4_general_debug.log` - Allgemeine Debug-Nachrichten

---

## Overview (English Summary)

A new export button has been implemented that packages all debug logs into a single ZIP file.

### What was implemented:

1. **Error Log Tracking** - A new logging system for errors was added
2. **ZIP Export Functionality** - All logs are exported to a ZIP file
3. **UI Button** - A 📦 button was added to the debug overlay

### The ZIP file contains:

1. `0_metadata.txt` - System information and summary
2. `1_sun_lighting_issue.log` - Useful data about the brightness/sun problem
3. `2_sleep_state_issue.log` - Log to debug why the game is in a weird state after reloading during sleep time
4. `3_error_logs.log` - Error logs
5. `4_general_debug.log` - General debug messages

---

## Technical Implementation

### Changes to `log_export_manager.gd`:

1. **Added ERROR_LOGS enum value**
   ```gdscript
   enum LogType {
       SUN_LIGHTING_ISSUE,
       SLEEP_STATE_ISSUE,
       GENERAL_DEBUG,
       ERROR_LOGS  // NEW
   }
   ```

2. **Added error_logs storage**
   ```gdscript
   var error_logs: Array[String] = []
   ```

3. **Added helper function**
   ```gdscript
   static func add_error(message: String) -> void:
       add_log(LogType.ERROR_LOGS, message)
   ```

4. **Added ZIP export function**
   ```gdscript
   static func export_all_logs_as_zip() -> String:
       # Creates a ZIP file with all logs
       # Returns the file path
   ```

5. **Added metadata generation**
   ```gdscript
   func _generate_metadata() -> String:
       # Generates system information
       # Includes OS, processor, video adapter info
       # Includes log counts and descriptions
   ```

### Changes to `debug_log_overlay.gd`:

1. **Added export_zip_button variable**
   ```gdscript
   var export_zip_button: Button
   ```

2. **Added button creation function**
   ```gdscript
   func _create_export_zip_button() -> void:
       # Creates orange 📦 button
       # Positioned after sleep button
   ```

3. **Added button handler**
   ```gdscript
   func _on_export_zip_pressed() -> void:
       # Calls LogExportManager.export_all_logs_as_zip()
       # Displays log counts and file path
   ```

4. **Updated button positions**
   - All buttons are now positioned correctly
   - ZIP button is at position 5 (after 📋 🗑 📄 ☀ 🌙)

### Documentation Updates:

1. **LOG_EXPORT_QUICKSTART.md**
   - Added ZIP export button to button layout
   - Added new section "Exporting All Logs to ZIP (Recommended)"
   - Added error log examples to programmatic usage

2. **LOG_EXPORT_SYSTEM.md**
   - Added "Error Logs" section to log types
   - Added ZIP export to "In-Game Export" section
   - Added `export_all_logs_as_zip()` to programmatic examples

### Test Files Created:

1. **tests/test_log_export_zip.gd**
   - Automated test script
   - Adds sample logs for each category
   - Tests ZIP creation
   - Verifies file existence and validity
   - Prints log counts

2. **tests/test_log_export_zip.tscn**
   - Test scene for running the test script

---

## How to Use

### For Users:

1. Start the game
2. Click the 📦 button in the top-left corner (6th button from left)
3. A ZIP file will be created in the logs directory
4. Find the file:
   - **Android**: Downloads folder > yougame-exports (accessible from Files app)
   - **Windows**: `%APPDATA%\Godot\app_userdata\YouGame\logs\`
   - **Linux**: `~/.local/share/godot/app_userdata/YouGame/logs/`

### For Developers:

```gdscript
# Add error logs
LogExportManager.add_error("Error message here")

# Export all logs to ZIP
var zip_path = LogExportManager.export_all_logs_as_zip()
if zip_path != "":
    print("ZIP created at: %s" % zip_path)
```

---

## ZIP File Structure

```
yougame_debug_logs_2026-01-22T20-30-45.zip
├── 0_metadata.txt              # System info, log counts, descriptions
├── 1_sun_lighting_issue.log    # Sun/brightness debug logs
├── 2_sleep_state_issue.log     # Sleep state debug logs
├── 3_error_logs.log            # Error messages and exceptions
└── 4_general_debug.log         # General debug messages
```

### Metadata File Example:

```
=== YouGame Debug Logs - System Information ===

Export Time: 2026-01-22T20:30:45
Game Version: 1.0.112

--- Log Counts ---
Sun Lighting Issue Logs: 15
Sleep State Issue Logs: 8
Error Logs: 3
General Debug Logs: 42

--- System Information ---
OS: Linux
Processor: Intel Core i7-9700K (8 cores)
Video Adapter: NVIDIA GeForce RTX 2070
Screen Size: (1920, 1080)
Locale: en_US

--- Description ---
1_sun_lighting_issue.log: Useful data about the brightness/sun problem
2_sleep_state_issue.log: Debug info for game state after reloading during sleep time
3_error_logs.log: Error messages and exceptions
4_general_debug.log: General debug messages and diagnostics

==============================================
```

---

## Benefits

1. **Easy to Share**: Single ZIP file contains all debugging information
2. **Complete Context**: Includes system information for better debugging
3. **Organized**: Files are numbered and named clearly
4. **Backward Compatible**: Individual log exports still work
5. **No Breaking Changes**: Existing code continues to work

---

## Testing

To test the ZIP export functionality:

1. Run the game normally and let it generate some logs
2. Click the 📦 button
3. Check that the ZIP file is created
4. Extract the ZIP and verify all 4 files are present
5. Check that each log file contains the expected data

Or run the automated test:
```bash
godot --headless --script tests/test_log_export_zip.tscn
```

---

## Files Modified

- `scripts/log_export_manager.gd` - Added error logs and ZIP export
- `scripts/debug_log_overlay.gd` - Added ZIP export button
- `LOG_EXPORT_QUICKSTART.md` - Updated documentation
- `LOG_EXPORT_SYSTEM.md` - Updated documentation

## Files Created

- `tests/test_log_export_zip.gd` - Test script
- `tests/test_log_export_zip.tscn` - Test scene

---

## Version

This feature was added in version 1.0.112+
