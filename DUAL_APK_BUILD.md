# Two APK Build Configuration

This repository is configured to build and release TWO separate APK files:

## APK Variants

### 1. Main Game APK (`YouGame-{version}.apk`)
- **Platform**: Godot 4.3
- **gradle_build**: disabled (not needed)
- **Size**: ~30 MB
- **Use case**: Main game for all users

### 2. Standalone Widget APK (`YouGame-Widget-{version}.apk`)
- **Platform**: Native Android (no Godot)
- **Build**: Pure Gradle build
- **Size**: ~50 KB
- **Use case**: Optional home screen widget that displays save game data

## Widget Features

The standalone widget APK displays:
- Last saved timestamp
- Current game day
- Player health percentage
- Torch inventory count
- Player position (X, Z coordinates)

The widget reads save data from a file written by the main game APK.

See [STANDALONE_WIDGET_IMPLEMENTATION.md](STANDALONE_WIDGET_IMPLEMENTATION.md) for architecture details.

## Building Locally

### Main Game APK
```bash
# Simple Godot export (no Gradle needed)
godot --headless --export-debug "Android" export/YouGame.apk
```

### Standalone Widget APK
```bash
# Native Android build
cd widget_app
./build_widget.sh

# Output: app/build/outputs/apk/debug/app-debug.apk
```

## Installation

Users need to install **both APKs**:

```bash
# Install main game
adb install YouGame-{version}.apk

# Install widget (optional)
adb install YouGame-Widget-{version}.apk
```

After installation:
1. Play the game and save at least once
2. Long-press home screen → Widgets
3. Add "YouGame Save Status" widget
4. Widget displays your save data

## CI/CD Build Process

The GitHub Actions workflow automatically:
1. Builds the main game APK (always succeeds)
2. Builds the standalone widget APK (simple Gradle build)
3. Creates releases with both APKs:
   - If both succeed: Both APKs uploaded with installation instructions
   - If widget fails: Only main game APK uploaded (doesn't block release)

## Why Two Separate APKs?

### Previous Approach (Problematic)
- Widget was integrated into Godot build using Gradle
- Required complex Android build template installation
- Frequent build failures due to version mismatches
- Widget issues blocked entire game release

### New Approach (Reliable)
- Widget is a standalone native Android app
- Simple, fast build process
- No Godot dependencies for widget
- Widget failures don't affect main game release
- Smaller, more maintainable code

## Export Presets

Export presets in `export_presets.cfg`:

- **preset.0** "Android" - Main game build (gradle_build=false)
- **preset.1** "Android Widget" - Legacy preset (can be removed or kept for compatibility)

The standalone widget doesn't use Godot export presets.

## Data Sharing

Widget reads save data from:
```
/storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
```

Main game writes to this file on every save via `SaveGameWidgetExporter`.

## Troubleshooting

### Widget shows "No save data"
- Ensure main game APK is installed
- Play game and save at least once
- Grant storage permissions to widget app

### Widget APK build fails
- Check Gradle version (8.0+ required)
- Build failure won't block main game release
- Only affects widget, not main game

### Widget not updating
- Widget updates when:
  - User manually refreshes widget
  - Android system periodic update
  - Widget is added to home screen
- Real-time updates require additional implementation

## Documentation

- **[STANDALONE_WIDGET_IMPLEMENTATION.md](STANDALONE_WIDGET_IMPLEMENTATION.md)** - Architecture and implementation details
- **[widget_app/README.md](widget_app/README.md)** - Widget development guide
- **[ANDROID_WIDGET_SUMMARY.md](ANDROID_WIDGET_SUMMARY.md)** - Old plugin-based implementation (legacy)

---

**Last Updated:** 2026-01-24  
**Architecture:** Standalone Native Widget  
**Build Status:** ✅ Simplified and Reliable
