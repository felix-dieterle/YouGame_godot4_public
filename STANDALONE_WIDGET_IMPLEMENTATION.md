# Standalone Widget Implementation - Architecture Change

## Problem

The previous widget implementation was integrated into the Godot build using Gradle, which caused constant build failures:
- Complex Android build template installation requirements
- Gradle/Godot version compatibility issues
- CI/CD build instability and frequent failures
- Error: "Android build template not installed" or "no version info for it exists"

## Solution

Separated the widget into a standalone native Android APK that runs independently from the main game.

## Architecture

### Previous (Godot Plugin-Based)
```
Main Game APK (with Gradle build enabled)
├── Godot Engine
├── Game Code
└── Widget Plugin (Java)
    ├── SaveGameWidgetPlugin.java
    └── SaveGameWidgetProvider.java
```

Problems:
- Requires Android build template installation
- Gradle build must be enabled
- Increases APK size
- Build failures block entire release

### New (Standalone Widget)
```
Main Game APK                    Standalone Widget APK
├── Godot Engine                 ├── Pure Android App
├── Game Code                    ├── SaveGameWidgetProvider.java
└── Widget Data Exporter         └── Widget UI (layouts, resources)
    (writes to file)                  (reads from file)
          │                                     │
          └─────── Shared File ─────────────────┘
                (widget_data.txt)
```

Benefits:
- ✅ No Godot dependency for widget
- ✅ Simple Gradle build (no build template needed)
- ✅ Smaller widget APK (~50KB vs ~30MB)
- ✅ Independent development and testing
- ✅ Build failures don't block main game release
- ✅ Easier to maintain and update

## Data Sharing

### File Location
```
/storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

### File Format
Simple key=value text format:
```
timestamp=1706097840000
day_count=5
current_health=75.0
torch_count=42
position_x=123.45
position_z=678.90
```

### Permissions
Widget requires:
- `READ_EXTERNAL_STORAGE` (API < 33)
- `READ_MEDIA_IMAGES` (API 33+)

## Build Process

### Main Game APK
```bash
# Build with Godot (no Gradle needed)
godot --headless --export-debug "Android" export/YouGame.apk
```

### Standalone Widget APK
```bash
# Build with Gradle
cd widget_app
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/app-debug.apk
```

### CI/CD Pipeline
```yaml
jobs:
  build-android:
    steps:
      - Build standard APK (always succeeds)
      - Build standalone widget APK (may fail without blocking)
      - Upload both APKs to artifacts
```

## Installation

Users now install **two separate APKs**:

1. **Main Game APK** (`YouGame-{version}.apk`)
   - Install normally
   - Writes widget data when saving game

2. **Widget APK** (`YouGame-Widget-{version}.apk`)
   - Install separately
   - Reads widget data from main game
   - Provides home screen widget

## Code Changes

### Modified Files

#### `scripts/save_game_widget_exporter.gd`
**Before:**
```gdscript
var _android_plugin = null

func _ready():
    if Engine.has_singleton("SaveGameWidget"):
        _android_plugin = Engine.get_singleton("SaveGameWidget")
        
func export_save_data(save_data):
    _android_plugin.exportSaveData(timestamp, day_count, ...)
```

**After:**
```gdscript
var widget_data_path = "/storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt"

func export_save_data(save_data):
    var file = FileAccess.open(widget_data_path, FileAccess.WRITE)
    file.store_line("timestamp=" + str(timestamp))
    file.store_line("day_count=" + str(day_count))
    # ... write other fields
    file.close()
```

### New Files

```
widget_app/
├── app/
│   ├── build.gradle                          # App build config
│   └── src/main/
│       ├── AndroidManifest.xml               # Widget permissions
│       ├── java/com/yougame/widget/
│       │   └── SaveGameWidgetProvider.java   # Widget logic
│       └── res/
│           ├── layout/widget_layout.xml      # Widget UI
│           ├── xml/savegame_widget_info.xml  # Widget metadata
│           └── drawable/                     # Widget graphics
├── build.gradle                              # Project build config
├── settings.gradle
├── gradle.properties
├── build_widget.sh                           # Build script
├── .gitignore                                # Exclude build artifacts
└── README.md                                 # Widget documentation
```

## Migration from Old Approach

### Removed (No Longer Needed)
- ❌ Android build template installation
- ❌ `install_android_build_template.sh` usage in CI/CD
- ❌ Gradle build template version checks
- ❌ `android/build/.gradle.build.version` file
- ❌ Complex Godot + Gradle integration
- ❌ Widget-enabled export preset (can be kept for compatibility)

### Kept (Still Used)
- ✅ `save_game_widget_exporter.gd` (modified to use file)
- ✅ Widget data export on save
- ✅ Widget clear on delete save
- ✅ SaveGameWidgetExporter autoload

## Testing

### Local Testing

#### Build Widget
```bash
cd widget_app
./build_widget.sh
```

#### Install Both APKs
```bash
# Install main game
adb install YouGame.apk

# Install widget
adb install widget_app/app/build/outputs/apk/debug/app-debug.apk
```

#### Verify Widget Data
```bash
# Play game and save
# Then check if data file exists:
adb shell ls -la /storage/emulated/0/Android/data/com.yougame.godot4/files/

# View widget data:
adb shell cat /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

#### Add Widget to Home Screen
1. Long-press home screen
2. Tap "Widgets"
3. Find "YouGame Save Status"
4. Drag to home screen
5. Widget displays save data

### CI/CD Testing

Widget build is now part of the CI/CD pipeline:
- Build runs on every PR and main branch push
- Widget build failure doesn't block main game release
- Both APKs uploaded to release if successful

## Troubleshooting

### Widget Shows "No save data"
**Cause:** Data file not found or not readable

**Solutions:**
1. Ensure main game is installed
2. Play game and save at least once
3. Grant storage permissions to widget app
4. Check file exists:
   ```bash
   adb shell ls /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
   ```

### Widget Build Fails in CI/CD
**Cause:** Gradle build issues

**Solutions:**
1. Check Gradle version (requires 8.0+)
2. Check Android SDK installation
3. Review build logs for specific errors
4. Widget failure won't block main game release

### Main Game Not Writing Data
**Cause:** File write permissions

**Solutions:**
1. Check logcat for file write errors
2. Ensure external storage is available
3. Check SaveGameWidgetExporter logs

## Future Enhancements

### Potential Improvements
1. **Direct Widget Update Trigger**
   - Add JNI bridge to send broadcast intent
   - Widget updates immediately after save
   - Currently relies on periodic updates

2. **Shared User ID**
   - Both APKs use same `sharedUserId`
   - Allows direct file access without external storage
   - More secure data sharing

3. **ContentProvider**
   - Implement ContentProvider in main game
   - Widget queries via ContentProvider API
   - More Android-standard approach

4. **Widget Configuration**
   - Let users choose which stats to display
   - Multiple widget sizes
   - Custom themes

## Comparison

| Aspect | Old (Plugin) | New (Standalone) |
|--------|-------------|------------------|
| APK Count | 1 (or 2 with/without widget) | 2 (main + widget) |
| Main APK Size | ~30-40 MB | ~30 MB |
| Widget APK Size | N/A (included) | ~50 KB |
| Build Complexity | High (Gradle + Godot) | Low (separate builds) |
| Build Reliability | Low (frequent failures) | High (simple builds) |
| Development | Coupled | Independent |
| Distribution | Single APK | Two APKs |
| User Installation | One APK | Two APKs |
| Maintenance | Complex | Simple |

## Conclusion

The standalone widget approach solves the chronic build issues by:
1. Eliminating Godot/Gradle integration complexity
2. Making builds more reliable and predictable
3. Enabling independent widget development
4. Providing clearer separation of concerns

**Trade-off:** Users must install two APKs instead of one, but this is a minor inconvenience compared to the development and build reliability benefits.

---

**Implementation Date:** 2026-01-24  
**Type:** Major Architecture Change  
**Impact:** Resolves chronic widget build failures  
**Status:** ✅ Ready for testing
