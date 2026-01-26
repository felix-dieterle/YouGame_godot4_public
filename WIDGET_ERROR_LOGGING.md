# Widget Error Logging - Accessing Diagnostic Information

## Overview

The YouGame widget now includes comprehensive error logging to help diagnose issues when the widget fails to initialize or cannot load save data. This document explains how to access and interpret these error logs.

## Problem Addressed

Previously, when the widget showed "widget kann nicht geladen werden" (widget cannot be loaded), there was no easy way for users to understand what went wrong. Error information was only available in Android's logcat, which requires developer tools and USB debugging.

## Solution

The widget now logs detailed error information to multiple locations:
1. **Android Logcat** - For developers with ADB access
2. **Error Log File** - Accessible via file manager or App Info (no developer tools needed)
3. **Widget Display** - Shows last error message directly on the widget

## How to Access Error Logs

### Method 1: Via File Manager (Easiest)

1. Open your Android file manager app
2. Navigate to: `Android/data/com.yougame.widget/files/`
3. Look for the file: `widget_errors.log`
4. Open the file to view error messages

**Full Path:**
```
/storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log
```

### Method 2: Via App Info (Android 11+)

1. Long-press the YouGame Widget app icon
2. Tap "App info" or the ⓘ icon
3. Tap "Storage" or "Storage & cache"
4. Tap "Manage storage" or "Browse data"
5. Navigate to the `files` folder
6. Open `widget_errors.log`

### Method 3: Via Widget Display

The widget will display the most recent error message directly on the home screen in the "Last Error" section when initialization fails.

### Method 4: Via ADB (For Developers)

If you have Android Debug Bridge (ADB) set up:

```bash
# Pull the log file
adb pull /storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log

# View real-time logs
adb logcat | grep -i YouGameWidget

# View filtered widget logs
adb logcat YouGameWidget:* *:S
```

## Understanding Error Messages

### Common Error Messages

#### 1. Save Data File Not Found
```
[ERROR] Save data file not found. Main game may not be installed or no save yet.
Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

**Cause:** The main game is not installed, or you haven't saved the game yet.

**Solution:**
- Install the main YouGame APK
- Play the game and save at least once
- Wait a moment and refresh the widget

#### 2. Permission Denied
```
[ERROR] Cannot read save data file. Permission denied. Check storage permissions.
Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

**Cause:** The widget doesn't have permission to read external storage.

**Solution:**
- Go to Android Settings → Apps → YouGame Widget
- Tap "Permissions"
- Enable "Files and media" or "Storage" permission
- Android 13+: Grant "Media" permissions

#### 3. Invalid Data Format
```
[ERROR] Invalid data format in save file. Line 5: day_count=abc
Exception: NumberFormatException
```

**Cause:** The save data file is corrupted or has invalid data.

**Solution:**
- Play the main game and save again
- If problem persists, the game's save system may have an issue

#### 4. I/O Error
```
[ERROR] Error reading save data file: Stream closed
Exception: IOException
```

**Cause:** File system error or the file is locked.

**Solution:**
- Force stop both the widget and main game apps
- Restart both apps
- Try accessing the widget again

## Log File Format

The error log uses a structured format for easy reading:

```
[2026-01-26 15:30:45] [ERROR] Save data file not found. Main game may not be installed or no save yet. Path: ...
  Exception: FileNotFoundException
  Message: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt (No such file or directory)
    at java.io.FileInputStream.open0(Native Method)
    at java.io.FileInputStream.open(FileInputStream.java:219)
    at java.io.FileInputStream.<init>(FileInputStream.java:157)
    at java.io.FileReader.<init>(FileReader.java:72)
    at com.yougame.widget.SaveGameWidgetProvider.readSaveData(SaveGameWidgetProvider.java:115)

[2026-01-26 15:35:12] [INFO] Widget enabled - first instance created
[2026-01-26 15:35:12] [INFO] Error log location: /storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log
[2026-01-26 15:35:15] [INFO] Widget update started
[2026-01-26 15:35:16] [INFO] Successfully read 9 lines from save data file
```

### Log Entry Components

- **Timestamp**: `[2026-01-26 15:30:45]` - When the event occurred
- **Level**: `[ERROR]`, `[INFO]` - Severity of the message
- **Message**: Human-readable description of what happened
- **Exception Details**: (For errors) Exception type, message, and stack trace

## Automatic Log Management

The widget automatically manages log file size:
- **Maximum Size**: 50 KB
- **Auto-Truncation**: When the log exceeds 50 KB, it automatically keeps only the most recent 50% of entries
- **No Manual Cleanup Needed**: Old logs are automatically removed

## Diagnostic Information Logged

The widget logs the following events:

### Successful Operations
- Widget enabled (first instance created)
- Widget disabled (last instance removed)
- Widget update started
- Data successfully read from save file
- Number of lines read from save file

### Error Conditions
- Save data file not found
- Permission denied when reading file
- Invalid data format in save file
- I/O errors during file reading
- Unexpected exceptions
- File reader close errors

## Privacy and Security

### What is Logged
- Error messages and timestamps
- File paths and permissions status
- Exception types and messages
- First 5 lines of stack traces

### What is NOT Logged
- No personal information
- No game save content (only metadata errors)
- No sensitive system information
- No location or device identifiers

### Log File Access
- The log file is stored in the app's private external storage
- Only accessible by:
  - The YouGame Widget app itself
  - File managers with storage permissions
  - Users through App Info
  - Developers with ADB access

## Troubleshooting with Logs

### Widget Shows "Widget Error - Check Logs"

1. Open the error log file (Method 1 or 2 above)
2. Look for the most recent `[ERROR]` entry
3. Follow the solution for that specific error message
4. After fixing the issue, update the widget:
   - Remove and re-add the widget, OR
   - Wait for the automatic update (every 30 minutes)

### No Error Log File Found

If you can't find `widget_errors.log`:
- The widget may not have been initialized yet
- Try adding the widget to your home screen first
- Check that you're looking in the correct path: `Android/data/com.yougame.widget/files/`
- Ensure you have permission to view app data folders

### Error Log Shows No Recent Errors

If the log file exists but shows no recent errors:
- The widget is working correctly
- The "No save data" message is expected if the game hasn't been saved yet
- Check the `[INFO]` entries to see normal operation logs

## Reporting Issues

When reporting widget issues, please include:
1. Screenshot of the widget showing the error
2. Contents of `widget_errors.log` (last 20-30 lines)
3. Android version
4. Whether the main game is installed
5. Whether you've saved the game at least once

## Technical Details

### Implementation
- **Class**: `WidgetErrorLogger` (new)
- **Logging Target**: Both Android Logcat and file system
- **File Location**: App's external files directory
- **Persistence**: Survives app restarts and updates
- **Tag**: `YouGameWidget` (for logcat filtering)

### Integration Points
- Widget initialization (`onEnabled`, `onDisabled`)
- Widget updates (`updateAppWidget`)
- Save data reading (`readSaveData`)
- File I/O operations
- Data parsing and validation

## Summary

The enhanced error logging system provides:
✅ **Easy Access** - View logs through file manager, no developer tools needed
✅ **Detailed Diagnostics** - Specific error messages explain what went wrong
✅ **User-Friendly** - Errors displayed directly on the widget
✅ **Automatic Management** - Logs managed automatically, no cleanup required
✅ **Privacy Conscious** - Only diagnostic information, no personal data
✅ **Developer Support** - Full stack traces available in logcat

This makes it much easier to diagnose and fix widget issues without requiring USB debugging or developer tools!
