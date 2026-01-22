# Android Widget Implementation

This document describes the Android home screen widget feature that displays savegame metrics and metadata.

## Overview

The Android widget provides at-a-glance information about the player's current game state without needing to launch the game. This is particularly useful for:
- Quick status check of your current game progress
- Bug analysis and debugging (know the exact state before reproducing an issue)
- Deciding whether to continue your current game or start fresh

## Widget Display

The widget shows the following information:

### Metadata
- **Last Saved**: Timestamp of when the game was last saved

### Game Progress
- **Day**: Current day count in the game
- **Health**: Player's current health percentage (0-100%)
- **Torches**: Number of torches in the player's inventory
- **Position**: Player's current position (X, Z coordinates)

## Technical Architecture

### Components

1. **SaveGameWidgetExporter** (`scripts/save_game_widget_exporter.gd`)
   - GDScript autoload singleton
   - Bridges between Godot and Android plugin
   - Exports save data when game saves
   - Platform-aware (only active on Android)

2. **SaveGameWidgetPlugin** (`android/plugins/savegame_widget/.../SaveGameWidgetPlugin.java`)
   - Godot Android plugin
   - Exposes methods to GDScript
   - Writes save data to SharedPreferences
   - Triggers widget updates

3. **SaveGameWidgetProvider** (`android/plugins/savegame_widget/.../SaveGameWidgetProvider.java`)
   - Android AppWidgetProvider
   - Reads data from SharedPreferences
   - Updates widget UI
   - Handles widget lifecycle events

4. **Widget Layout** (`android/plugins/savegame_widget/.../res/layout/savegame_widget_layout.xml`)
   - Visual layout definition
   - Displays all savegame metrics
   - Styled with game theme colors

### Data Flow

```
Game Save Event
    ↓
SaveGameManager.save_game()
    ↓
SaveGameWidgetExporter.export_save_data()
    ↓
SaveGameWidgetPlugin.exportSaveData() [Android Plugin]
    ↓
SharedPreferences (Android storage)
    ↓
SaveGameWidgetProvider updates widget UI
    ↓
Widget displays on home screen
```

## Installation and Usage

### For Players

1. **Install the game** from the APK
2. **Play and save** at least once to generate save data
3. **Add widget to home screen**:
   - Long-press on home screen
   - Select "Widgets"
   - Find "YouGame Save Status"
   - Drag to home screen
4. **Widget automatically updates** when you save the game

### For Developers

#### Building with the Plugin

The plugin is automatically included when building with Gradle:

1. Ensure `export_presets.cfg` has `gradle_build/use_gradle_build=true`
2. Build normally: `./build.sh` or through Godot editor
3. The plugin is compiled and included in the APK

#### Plugin Structure

```
android/plugins/savegame_widget/
├── build.gradle                    # Gradle build configuration
├── savegame_widget.gdap            # Godot plugin configuration
├── src/main/
│   ├── AndroidManifest.xml         # Widget registration
│   ├── java/com/yougame/savegamewidget/
│   │   ├── SaveGameWidgetPlugin.java      # Godot plugin
│   │   └── SaveGameWidgetProvider.java    # Widget provider
│   └── res/
│       ├── drawable/
│       │   └── widget_background.xml      # Widget background style
│       ├── layout/
│       │   └── savegame_widget_layout.xml # Widget layout
│       ├── values/
│       │   └── strings.xml                # UI strings
│       └── xml/
│           └── savegame_widget_info.xml   # Widget metadata
```

## Customization

### Modifying Widget Appearance

Edit `savegame_widget_layout.xml` to change:
- Layout structure
- Text sizes and colors
- Widget dimensions
- Additional data fields

### Adding New Data Fields

1. Update `SaveGameWidgetPlugin.exportSaveData()` to accept new parameters
2. Write new data to SharedPreferences
3. Update `SaveGameWidgetProvider.updateAppWidget()` to read and display new data
4. Modify `savegame_widget_layout.xml` to add UI elements
5. Update `SaveGameWidgetExporter.export_save_data()` to pass new data

### Changing Update Frequency

Edit `savegame_widget_info.xml`:
- `android:updatePeriodMillis`: Minimum update interval (currently 30 minutes)
- Note: Widgets update immediately on save regardless of this setting

## Platform Support

- **Android**: Fully supported (API 21+)
- **Other platforms**: Plugin gracefully disabled on non-Android platforms

## Troubleshooting

### Widget shows "No save data available"
- Ensure you've saved the game at least once
- Check that the game has proper storage permissions
- Try removing and re-adding the widget

### Widget not updating
- Save the game to trigger an update
- Check logcat for errors: `adb logcat | grep SaveGame`
- Verify SharedPreferences are being written

### Build errors
- Ensure Gradle build is enabled in export presets
- Check that Godot 4.3+ is being used
- Verify Android build tools are properly installed

## Future Enhancements

Possible improvements:
- [ ] Additional metrics (air level, flint stones, mushrooms, etc.)
- [ ] Interactive widget buttons (launch game, delete save, etc.)
- [ ] Multiple widget sizes (small, medium, large)
- [ ] Widget configuration activity
- [ ] Historical data (previous saves, progress over time)
- [ ] Screenshots from save points

## License

This widget implementation follows the same license as the main YouGame project.
