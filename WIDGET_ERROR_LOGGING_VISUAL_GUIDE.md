# Widget Error Logging - Visual Guide

## Accessing Widget Error Logs (No Developer Tools Needed!)

This guide shows you how to access widget error logs when the widget displays "Widget Error - Check Logs" or fails to load properly.

---

## Method 1: File Manager (Recommended - Works on All Android Versions)

### Step 1: Open File Manager
Open your Android device's file manager app. Common apps include:
- "Files" (Google Files)
- "My Files" (Samsung)
- "File Manager" (other manufacturers)

### Step 2: Navigate to Widget Files
Navigate to the following path:
```
Android → data → com.yougame.widget → files
```

**Full Path:**
```
/storage/emulated/0/Android/data/com.yougame.widget/files/
```

### Step 3: Open Error Log
Look for the file: `widget_errors.log`

Tap to open it with a text viewer.

### What You'll See
```
[2026-01-26 15:30:45] [ERROR] Save data file not found. Main game may not be installed or no save yet.
Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
  Exception: FileNotFoundException
  Message: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt (No such file or directory)

[2026-01-26 15:35:12] [INFO] Widget enabled - first instance created
[2026-01-26 15:35:12] [INFO] Error log location: /storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log
```

---

## Method 2: App Info (Android 11+)

### Step 1: Open App Info
1. Long-press the "YouGame Widget" app icon in your app drawer
2. Tap "App info" or the information icon (ⓘ)

**Alternative:**
- Go to Settings → Apps → YouGame Widget

### Step 2: Access Storage
1. Tap "Storage" or "Storage & cache"
2. Tap "Manage storage" or "Browse data"

### Step 3: Navigate to Files
1. You should see a file browser
2. Navigate to the `files` folder
3. Open `widget_errors.log`

---

## Method 3: On the Widget Itself

### Quick Diagnosis
The widget displays the most recent error message directly in the "Last Error" section when an initialization error occurs.

**Widget Display States:**

**Normal Operation:**
```
┌─────────────────────────────┐
│ YouGame Save Status         │
│ Last saved: Jan 26, 15:30   │
│ Day: 5          Health: 85% │
│ Torches: 12     Pos: 120, 45│
│ ─────────────────────────── │
│ Errors: 0       Logs: 245   │
│ No errors                   │
└─────────────────────────────┘
```

**Error State:**
```
┌─────────────────────────────┐
│ YouGame Save Status         │
│ Widget Error - Check Logs   │
│ Day: --         Health: --% │
│ Torches: --     Pos: --, -- │
│ ─────────────────────────── │
│ Errors: --      Logs: --    │
│ Save data file not found.   │
│ Main game may not be...     │
└─────────────────────────────┘
```

---

## Method 4: ADB (For Developers Only)

If you have Android Debug Bridge (ADB) installed and USB debugging enabled:

### Pull Log File
```bash
adb pull /storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log
```

### View Real-Time Logs
```bash
# All widget logs
adb logcat | grep -i YouGameWidget

# Error logs only
adb logcat YouGameWidget:E *:S

# Detailed logs
adb logcat YouGameWidget:* *:S
```

### Example Output
```
01-26 15:30:45.123 12345 12367 E YouGameWidget: Save data file not found. Main game may not be installed or no save yet.
01-26 15:30:45.125 12345 12367 E YouGameWidget: Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
01-26 15:35:12.456 12345 12367 I YouGameWidget: Widget enabled - first instance created
01-26 15:35:12.458 12345 12367 I YouGameWidget: Error log location: /storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log
```

---

## Common Error Messages and Solutions

### Error: "Save data file not found"

**Full Message:**
```
[ERROR] Save data file not found. Main game may not be installed or no save yet.
Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

**What it means:** The widget cannot find the save data file from the main game.

**Solutions:**
1. ✅ Install the main YouGame APK (`com.yougame.godot4`)
2. ✅ Play the game and save at least once
3. ✅ Wait a moment for the widget to update (or remove and re-add it)

---

### Error: "Cannot read save data file. Permission denied"

**Full Message:**
```
[ERROR] Cannot read save data file. Permission denied. Check storage permissions.
Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

**What it means:** The widget doesn't have permission to read external storage.

**Solutions:**
1. ✅ Open Settings → Apps → YouGame Widget
2. ✅ Tap "Permissions"
3. ✅ Enable "Files and media" or "Storage" permission
4. ✅ On Android 13+: Grant "Photos and videos" or "Media" permissions

---

### Error: "Invalid data format in save file"

**Full Message:**
```
[ERROR] Invalid data format in save file. Line 5: day_count=abc
Exception: NumberFormatException
```

**What it means:** The save data file is corrupted or has invalid data.

**Solutions:**
1. ✅ Play the main game and save again
2. ✅ If the problem persists, reinstall the main game APK
3. ✅ Report the issue with the error log contents

---

### Error: "Error reading save data file"

**Full Message:**
```
[ERROR] Error reading save data file: Stream closed
Exception: IOException
```

**What it means:** A file system error occurred while reading the save data.

**Solutions:**
1. ✅ Force stop both the widget app and the main game
2. ✅ Restart your device
3. ✅ Check available storage space
4. ✅ Try accessing the widget again

---

## Log File Format Explained

### Structure
```
[TIMESTAMP] [LEVEL] MESSAGE
  Exception: ExceptionType
  Message: Detailed exception message
    at StackTraceLine1
    at StackTraceLine2
    ...
```

### Example Entry
```
[2026-01-26 15:30:45] [ERROR] Save data file not found. Main game may not be installed or no save yet.
Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
  Exception: FileNotFoundException
  Message: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt (No such file or directory)
    at java.io.FileInputStream.open0(Native Method)
    at java.io.FileInputStream.open(FileInputStream.java:219)
    at java.io.FileInputStream.<init>(FileInputStream.java:157)
    at java.io.FileReader.<init>(FileReader.java:72)
    at com.yougame.widget.SaveGameWidgetProvider.readSaveData(SaveGameWidgetProvider.java:115)
```

### Components

**Timestamp:** `[2026-01-26 15:30:45]`
- When the error occurred
- Format: YYYY-MM-DD HH:MM:SS

**Level:** `[ERROR]` or `[INFO]`
- ERROR: Something went wrong
- INFO: Normal operation information

**Message:** Human-readable description
- Explains what happened
- Includes relevant details (file paths, etc.)

**Exception Details:** (For errors only)
- Exception type (FileNotFoundException, IOException, etc.)
- Detailed error message from the system
- Stack trace (shows where in the code the error occurred)

---

## File Browser Screenshots (Typical Locations)

### Google Files App
```
📁 Files
  📁 Android
    📁 data
      📁 com.yougame.widget
        📁 files
          📄 widget_errors.log  ← This file!
```

### Samsung My Files
```
📁 Internal storage
  📁 Android
    📁 data
      📁 com.yougame.widget
        📁 files
          📄 widget_errors.log  ← This file!
```

---

## Sharing Error Logs

### When Reporting Issues
If you're reporting a widget issue, please include:

1. **Screenshot of widget** showing the error
2. **Last 20-30 lines** of `widget_errors.log`
3. **Android version** (Settings → About phone)
4. **Main game installed?** (Yes/No)
5. **Have you saved the game?** (Yes/No)

### How to Copy Log Contents

**Method 1: File Manager**
1. Open `widget_errors.log` in file manager
2. Long-press to select all text
3. Tap "Copy" or "Share"
4. Paste into your issue report

**Method 2: ADB**
```bash
adb pull /storage/emulated/0/Android/data/com.yougame.widget/files/widget_errors.log
# Then open the pulled file and copy contents
```

---

## Privacy Note

### What's in the Logs
- ✅ Error timestamps
- ✅ File paths
- ✅ Exception types and messages
- ✅ Stack traces (technical debugging info)

### What's NOT in the Logs
- ❌ No personal information
- ❌ No game save content
- ❌ No device identifiers
- ❌ No location data
- ❌ No passwords or credentials

**The logs are safe to share when reporting issues!**

---

## Additional Help

For more detailed information, see:
- `WIDGET_ERROR_LOGGING.md` - Complete error logging documentation
- `widget_app/README.md` - Widget app overview and setup
- `WIDGET_LOADING_FIX.md` - Previous widget loading issue fix

For issues not covered here, please open a GitHub issue with your error log contents.
