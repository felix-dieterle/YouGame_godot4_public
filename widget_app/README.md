# YouGame Widget - Standalone Android Widget App

This is a standalone native Android application that provides a home screen widget for YouGame. It displays save game data from the main YouGame app.

## Why Separate?

The widget was previously integrated into the Godot build using Gradle, which caused constant build failures due to:
- Complex Android build template installation requirements
- Gradle/Godot version compatibility issues  
- CI/CD build instability

This standalone approach:
- ✅ Eliminates Godot dependency for the widget
- ✅ Simplifies build process (pure Android project)
- ✅ No more gradle build template errors
- ✅ Smaller, faster widget APK
- ✅ Independent development and testing

## Architecture

### Data Sharing
- **Main Game APK** (`com.yougame.godot4`): Writes save data to external files directory
- **Widget APK** (`com.yougame.widget`): Reads save data from main game's external files
- **File Location**: `/storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt`
- **Format**: Simple key=value text file

### Widget Features
Displays:

**Save Game Data:**
- Last saved timestamp
- Current game day
- Player health percentage
- Torch inventory count
- Player position (X, Z coordinates)

**Log Data:**
- Error count
- Total log count (all categories)
- Last error message

## Building

### Prerequisites
- JDK 11+
- Android SDK with API 33
- Gradle 8.0+

### Build Commands

```bash
# Using the build script (recommended)
./build_widget.sh

# Or using Gradle directly
./gradlew assembleDebug

# Output APK location
app/build/outputs/apk/debug/app-debug.apk
```

## Installation

### Option 1: Install Both APKs
```bash
# Install main game
adb install YouGame.apk

# Install widget
adb install YouGame-Widget.apk
```

### Option 2: Build and Install
```bash
# Build widget
cd widget_app
./build_widget.sh

# Install
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Adding Widget to Home Screen

1. Long-press on Android home screen
2. Tap "Widgets"
3. Find "YouGame Save Status"
4. Drag to desired location
5. Widget shows "No save data" until first game save

## Permissions

The widget requires:
- `READ_EXTERNAL_STORAGE` (API < 33): To read save data from main game
- `READ_MEDIA_IMAGES` (API 33+): Modern Android permission equivalent

These permissions are only used to read the widget_data.txt file written by the main game.

## File Structure

```
widget_app/
├── app/
│   ├── build.gradle                          # App-level Gradle config
│   └── src/main/
│       ├── AndroidManifest.xml               # App manifest with permissions
│       ├── java/com/yougame/widget/
│       │   └── SaveGameWidgetProvider.java   # Widget logic
│       └── res/
│           ├── layout/widget_layout.xml      # Widget UI
│           ├── xml/savegame_widget_info.xml  # Widget metadata
│           ├── drawable/                     # Widget graphics
│           └── values/strings.xml            # Widget strings
├── build.gradle                              # Project-level Gradle config
├── settings.gradle                           # Gradle settings
├── gradle.properties                         # Gradle properties
└── build_widget.sh                           # Build script
```

## Development

### Modifying Widget Appearance
Edit `app/src/main/res/layout/widget_layout.xml`

### Adding New Data Fields
1. Update main game's `save_game_widget_exporter.gd` to write new field
2. Update `SaveGameWidgetProvider.java` to read new field
3. Update `widget_layout.xml` to display new field

### Testing
```bash
# Build and install
./build_widget.sh
adb install -r app/build/outputs/apk/debug/app-debug.apk

# View widget logs
adb logcat | grep -i widget
```

## Troubleshooting

### Widget shows "widget kann nicht geladen werden" (cannot be loaded)
- This was caused by missing launcher icons (fixed in latest version)
- Ensure you have the latest widget APK with all icon resources
- Reinstall the widget APK if upgrading from an older version
- See `WIDGET_LOADING_FIX.md` for detailed fix information

### Widget shows "No save data"
- Ensure main game APK is installed
- Play the game and save at least once
- Check that widget_data.txt exists:
  ```bash
  adb shell ls -la /storage/emulated/0/Android/data/com.yougame.godot4/files/
  ```

### Permission errors
- Grant storage permission to widget app in Android settings
- For Android 13+, ensure READ_MEDIA_IMAGES permission is granted

### Widget not appearing in widget list
- Ensure widget APK is installed
- Restart launcher app
- Check logcat for errors

## CI/CD Integration

The widget is built separately from the main game in the CI/CD pipeline:
1. Main game builds without Gradle (fast, simple)
2. Widget builds as standalone Android app
3. Both APKs are uploaded to releases

See `.github/workflows/build.yml` for implementation.
