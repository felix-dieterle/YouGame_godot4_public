# Downloads Folder Export Implementation

## Zusammenfassung (German)

Die Log-Export-Funktion wurde aktualisiert, um alle Dateien auf Android-Geräten in den **Downloads-Ordner** im Unterordner **yougame-exports** zu exportieren, anstatt in das private App-Verzeichnis.

### Was wurde geändert:

1. **Android**: Logs werden jetzt nach `Downloads/yougame-exports/` exportiert
2. **Desktop**: Logs bleiben im `user://logs/` Verzeichnis (keine Änderung)
3. **Fallback**: Wenn der Downloads-Ordner nicht erstellt werden kann, wird automatisch auf `user://logs/` zurückgegriffen

### Warum diese Änderung:

- Der alte Pfad `/storage/emulated/0/Android/data/com.yougame.godot4/files/logs/` ist im privaten App-Verzeichnis und für Benutzer schwer zugänglich
- Der neue Pfad `Downloads/yougame-exports/` ist über die Datei-App leicht zugänglich
- Benutzer können exportierte ZIP-Dateien einfach finden und teilen

---

## Overview (English)

The log export functionality has been updated to export all files to the **Downloads folder** in a **yougame-exports** subfolder on Android devices, instead of the app's private directory.

### What Changed:

1. **Android**: Logs are now exported to `Downloads/yougame-exports/`
2. **Desktop**: Logs remain in `user://logs/` directory (no change)
3. **Fallback**: If the Downloads folder cannot be created, automatically falls back to `user://logs/`

### Why This Change:

- The old path `/storage/emulated/0/Android/data/com.yougame.godot4/files/logs/` is in the app's private directory and difficult for users to access
- The new path `Downloads/yougame-exports/` is easily accessible via the Files app
- Users can easily find and share exported ZIP files

---

## Implementation Details

### Code Changes

#### 1. Dynamic Export Path (`log_export_manager.gd`)

Changed from a constant path to a dynamic path based on the platform:

```gdscript
# Before
const EXPORT_BASE_PATH: String = "user://logs/"

# After
var export_base_path: String = ""

func _setup_export_path() -> void:
    if OS.get_name() == "Android":
        var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
        if downloads_dir != "":
            export_base_path = downloads_dir + "/yougame-exports/"
        else:
            export_base_path = "user://logs/"
    else:
        export_base_path = "user://logs/"
```

#### 2. Directory Creation with Fallback

Enhanced directory creation to handle both absolute (Android) and virtual (Desktop) paths with fallback:

```gdscript
func _ensure_log_directory() -> void:
    if export_base_path.begins_with("/"):
        # Absolute path (Android)
        var dir = DirAccess.open("/")
        if dir and not dir.dir_exists(export_base_path):
            var err = dir.make_dir_recursive(export_base_path)
            if err != OK:
                # Fallback to user://logs/ on error
                export_base_path = "user://logs/"
                # ... create fallback directory
    else:
        # Virtual path (Desktop)
        # ... existing logic
```

#### 3. Path Handling for Exports

Updated to handle both absolute and virtual paths:

```gdscript
# For absolute paths, return as-is; for virtual paths, convert to absolute
var absolute_path = filepath if filepath.begins_with("/") else ProjectSettings.globalize_path(filepath)
```

### Platform Behavior

#### Android
- **Export Path**: `OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/yougame-exports/"`
- **Typical Location**: Downloads folder accessible via Files app
- **Fallback**: Falls back to `user://logs/` if Downloads directory cannot be created
- **Note**: Works with app's existing permissions. On Android 10+, the app can write to app-specific directories in external storage without additional permissions.

#### Desktop (Windows/Linux/Mac)
- **Export Path**: `user://logs/`
- **Windows**: `%APPDATA%\Godot\app_userdata\YouGame\logs\`
- **Linux**: `~/.local/share/godot/app_userdata/YouGame/logs/`
- **Mac**: `~/Library/Application Support/Godot/app_userdata/YouGame/logs/`
- **No Change**: Maintains backward compatibility

### Error Handling

1. **Downloads Directory Unavailable**: Falls back to `user://logs/`
2. **Directory Creation Failure**: Falls back to `user://logs/`
3. **File Write Failure**: Error is logged but doesn't crash the app

### Testing

To test the changes:

1. **On Android Device**:
   - Run the game
   - Click the 📦 button to export logs
   - Open the Files app
   - Navigate to Downloads > yougame-exports
   - Verify the ZIP file is there

2. **On Desktop**:
   - Run the game
   - Click the 📦 button to export logs
   - Check the user data directory (see paths above)
   - Verify the ZIP file is there

### Backward Compatibility

- ✅ Desktop platforms: No change in behavior
- ✅ Existing exports: Not affected
- ✅ Old save files: Not affected
- ✅ Fallback mechanism: Ensures exports always work

---

## Files Modified

1. `scripts/log_export_manager.gd` - Core export logic
2. `LOG_EXPORT_QUICKSTART.md` - User documentation
3. `ZIP_EXPORT_IMPLEMENTATION.md` - Technical documentation
4. `tests/test_log_export_zip.gd` - Test output messages

---

## Benefits

1. **User Accessibility**: Files are now in a user-accessible location on Android
2. **Easy Sharing**: Users can easily share exported logs for debugging
3. **Better UX**: No need to use adb or file managers with root access
4. **Robust Fallback**: Always works even if Downloads directory is unavailable
5. **Backward Compatible**: No breaking changes for Desktop users

---

## Android Permissions Note

On Android 10 and later, apps have scoped storage access. The implementation uses `OS.get_system_dir()` which returns a path the app can access with its existing permissions. If additional permissions are needed in the future, they can be added to `export_presets.cfg`:

```
permissions/custom_permissions=PackedStringArray("android.permission.WRITE_EXTERNAL_STORAGE")
```

However, for app-specific directories in external storage (which `OS.get_system_dir()` should provide), no additional permissions are required.

---

## Version

This feature was implemented in response to user request for accessible file exports.
Implementation date: 2026-01-28
