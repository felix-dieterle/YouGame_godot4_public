# Save/Load Game System

## Overview

This document describes the save/load game system implemented for YouGame. The system allows players to save their progress when exiting the game or when bedtime/pause starts, and optionally resume from the saved state on the next game start.

## Features

### Automatic Save Points

The game automatically saves in the following situations:

1. **When quitting via pause menu**: Pressing ESC to open the pause menu and selecting "Quit to Desktop" will save the current game state before exiting.

2. **When bedtime starts**: When the day/night cycle reaches sunset and night begins (lockout period), the game state is automatically saved.

### Manual Save/Load Options

When starting the game:
- If a save file exists, a start menu appears with two options:
  - **Continue Game**: Loads the saved game state and resumes from where you left off
  - **New Game**: Deletes the existing save and starts a fresh game

### What Gets Saved

The save system stores the following data:

#### Player Data
- Player position (x, y, z coordinates)
- Player rotation (facing direction)
- Camera mode (first-person or third-person view)

#### World Data
- World seed (for chunk generation consistency)
- Current player chunk position

#### Day/Night Cycle Data
- Current time of day
- Lockout state (whether night has started)
- Lockout end time (when the player can resume after night)

#### Metadata
- Save file version
- Timestamp of when the save was created

## Implementation Details

### Architecture

The save system is implemented using a singleton pattern with the `SaveGameManager` autoload:

```gdscript
# Access from any script
SaveGameManager.save_game()
SaveGameManager.load_game()
SaveGameManager.has_save_file()
```

### File Format

- **File Path**: `user://game_save.cfg`
- **Format**: Godot's ConfigFile format (INI-style, performant key-value storage)
- **Storage**: User data directory (platform-specific)
  - Windows: `%APPDATA%/Godot/app_userdata/YouGame/`
  - Linux: `~/.local/share/godot/app_userdata/YouGame/`
  - Android: App-specific data directory

### Performance

The system is designed to be performant:

1. **ConfigFile format**: Uses Godot's optimized ConfigFile class for fast I/O
2. **Minimal data**: Only essential game state is saved, not entire world data
3. **Asynchronous-friendly**: Save operations are quick and don't block gameplay
4. **Chunk-based world**: World is procedurally generated from seed, so only seed needs to be saved

## Usage for Developers

### Saving Game State

To trigger a manual save:

```gdscript
# Update player data
SaveGameManager.update_player_data(
    player.global_position,
    player.rotation.y,
    player.is_first_person
)

# Update world data
SaveGameManager.update_world_data(
    world_manager.WORLD_SEED,
    world_manager.player_chunk
)

# Update day/night data
SaveGameManager.update_day_night_data(
    day_night_cycle.current_time,
    day_night_cycle.is_locked_out,
    day_night_cycle.lockout_end_time
)

# Save to file
SaveGameManager.save_game()
```

### Loading Game State

Loading is automatic during game initialization. Each system loads its own data:

```gdscript
# In Player._ready()
if SaveGameManager.has_save_file():
    if SaveGameManager.load_game():
        var player_data = SaveGameManager.get_player_data()
        global_position = player_data["position"]
        rotation.y = player_data["rotation_y"]
        # ... restore other player state
```

### Adding New Save Data

To add new data to the save system:

1. Update the `save_data` dictionary in `SaveGameManager`
2. Add getter/setter methods for the new data
3. Update the `save_game()` method to write the data
4. Update the `load_game()` method to read the data
5. Update the relevant game scripts to use the new save data

Example:

```gdscript
# In SaveGameManager
var save_data: Dictionary = {
    "inventory": {
        "items": [],
        "gold": 0
    },
    # ... existing data
}

func update_inventory_data(items: Array, gold: int):
    save_data["inventory"]["items"] = items
    save_data["inventory"]["gold"] = gold

func get_inventory_data() -> Dictionary:
    return save_data["inventory"]
```

## Testing

A comprehensive test suite is included in `tests/test_save_load.gd`:

### Running Tests

```bash
# Run from project root
godot --headless --path . res://tests/test_scene_save_load.tscn
```

### Test Coverage

The test suite validates:
- ✓ SaveGameManager autoload accessibility
- ✓ Saving and loading player data
- ✓ Saving and loading world data
- ✓ Saving and loading day/night cycle data
- ✓ Save file deletion
- ✓ Data persistence across save/load cycles
- ✓ Data accuracy (values match after load)

## Files Modified

- `scripts/save_game_manager.gd` - New: Core save/load system
- `scripts/pause_menu.gd` - Modified: Added save on quit
- `scripts/player.gd` - Modified: Added load on start
- `scripts/day_night_cycle.gd` - Modified: Added save on night start and load on start
- `scripts/ui_manager.gd` - Modified: Added start menu with continue/new game options
- `project.godot` - Modified: Added SaveGameManager autoload
- `tests/test_save_load.gd` - New: Test suite for save/load functionality

## User Experience

### First Time Players

When starting the game for the first time (no save file exists):
- Game starts normally
- No start menu appears
- Player begins at the starting location

### Returning Players

When starting the game with an existing save file:
1. Start menu appears with dark overlay
2. Game is paused
3. Two options are presented:
   - "Continue Game" - Resume from saved position
   - "New Game" - Start fresh (deletes save)
4. After selection, game unpauses and begins

### During Gameplay

- Progress is automatically saved when quitting via pause menu
- Progress is automatically saved when night falls
- No manual save button required (automatic save points)

## Future Enhancements

Potential improvements for the save system:

1. **Multiple Save Slots**: Allow players to have multiple saved games
2. **Quick Save**: Add a hotkey for manual saves during gameplay
3. **Save File Management**: UI for viewing/deleting save files
4. **Cloud Saves**: Integration with platform-specific cloud save systems
5. **Autosave Intervals**: Periodic automatic saves during gameplay
6. **Save Icons**: Visual indicator when game is saving
7. **Compressed Saves**: Use compression for larger save files
8. **Save Validation**: Checksum/hash validation to detect corrupted saves

## Troubleshooting

### Save File Not Found

If the save file is not loading:
- Check that the file exists in `user://game_save.cfg`
- Verify file permissions in the user data directory
- Check console output for load errors

### Save Data Corrupted

If save data appears incorrect:
- The old day/night cycle save file (`user://day_night_save.cfg`) is still supported as fallback
- Delete the save file and start a new game if corruption persists
- Check console output for parsing errors

### Performance Issues

The save system is designed to be fast, but if you experience lag:
- Saves are synchronous and may briefly pause on very slow storage
- Consider adding async file operations for large save files (future enhancement)
- Reduce save frequency if saving too often

## Security Considerations

- Save files are stored locally in user data directory
- Files are plain text (ConfigFile format) and can be edited
- No sensitive data should be stored in save files
- Consider encryption for competitive/online features (future enhancement)
