# SaveGameWidget Android Plugin

This directory contains the Android widget plugin that displays save game information on the device's home screen.

## Building the Widget

The widget needs to be built into an AAR (Android Archive) file before it can be included in the APK export.

### Prerequisites

- Java 11 or higher
- Android SDK with API level 33
- Gradle 8.1+ (or use the wrapper)

### Build Instructions

#### Option 1: Using the build script (Recommended)

```bash
# From the repository root
./android/plugins/savegame_widget/build_widget.sh
```

#### Option 2: Manual build

```bash
# From the repository root
cd android/plugins/savegame_widget

# Create Gradle wrapper if needed
gradle wrapper --gradle-version=8.1

# Build the AAR
./gradlew assembleRelease

# Copy to expected location
cp build/outputs/aar/savegame_widget-release.aar savegame_widget.aar
```

### Verifying the Build

After building, you should see:
- `android/plugins/savegame_widget/savegame_widget.aar` - The plugin binary

The widget will now be automatically included when exporting the APK from Godot.

### Integration with APK Export

The widget is configured in `export_presets.cfg` and will be included in release APKs. The `.gdap` file tells Godot to bundle the AAR into the APK.

**Note:** The AAR file must exist before exporting the APK. If you get an error about missing plugin binary, run the build script above.

## Widget Features

- Displays save game information on Android home screen
- Shows day count, health, torches, and player position
- Updates automatically when game is saved
- Lightweight and doesn't drain battery

## Troubleshooting

### "Could not find version of build tools that matches Target SDK"

This warning can be safely ignored. The build will use the closest available SDK version.

### "Plugin binary not found"

Run the build script to create the AAR file:
```bash
./android/plugins/savegame_widget/build_widget.sh
```

### Build fails with "JAVA_HOME not set"

Ensure Java 11 or higher is installed and JAVA_HOME is set:
```bash
export JAVA_HOME=/path/to/java11
```
