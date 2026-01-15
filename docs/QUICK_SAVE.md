# Quick Save Feature Documentation

## Overview

The YouGame project includes a comprehensive quick save system that automatically saves the game state at critical moments and restores it when the game is restarted.

## How It Works

### Automatic Saving

The game automatically saves (quick save) in the following situations:

1. **When Night Begins**: When the sunset animation completes and the player enters the night lockout period, the game automatically saves all current state.

2. **When Quitting via Menu**: When the player selects "Quit to Desktop" from the pause menu, the game saves before exiting.

### Automatic Loading

When the game starts, if a save file exists, it is automatically loaded and the following state is restored:

- Player position (3D coordinates)
- Player rotation/orientation (Y-axis rotation)
- Camera mode (first-person or third-person)
- Current time of day
- Time scale (game speed multiplier)
- Night lockout state
- World seed and chunk information
- Master volume setting
- Ruler overlay visibility

### Save File Location

The quick save is stored as: `user://game_save.cfg`

On different operating systems, this translates to:
- **Linux**: `~/.local/share/godot/app_userdata/YouGame/game_save.cfg`
- **Windows**: `%APPDATA%/Godot/app_userdata/YouGame/game_save.cfg`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/YouGame/game_save.cfg`

## Technical Implementation

### Components

1. **SaveGameManager** (`scripts/save_game_manager.gd`)
   - Singleton autoload that manages save/load operations
   - Uses ConfigFile for efficient key-value storage
   - Auto-loads save data on game startup

2. **DayNightCycle** (`scripts/day_night_cycle.gd`)
   - Triggers save when night begins (in sunset completion handler)
   - Loads time and lockout state on startup

3. **PauseMenu** (`scripts/pause_menu.gd`)
   - Triggers save when quitting via menu (in `_on_quit_pressed()`)

4. **Player** (`scripts/player.gd`)
   - Loads saved position and orientation on startup (in `_ready()` via `_load_saved_state()`)

### Save Data Structure

```gdscript
{
  "player": {
    "position": Vector3,      # 3D position in world
    "rotation_y": float,      # Y-axis rotation (orientation)
    "is_first_person": bool   # Camera mode
  },
  "world": {
    "seed": int,              # World generation seed
    "player_chunk": Vector2i  # Current chunk coordinates
  },
  "day_night": {
    "current_time": float,         # Time in day cycle (0-1800 seconds)
    "is_locked_out": bool,         # Night lockout active
    "lockout_end_time": float,     # Unix timestamp when lockout ends
    "time_scale": float            # Game speed multiplier
  },
  "settings": {
    "master_volume": float,        # Master volume (0-100)
    "ruler_visible": bool          # Ruler overlay visibility
  },
  "meta": {
    "version": string,        # Save format version
    "timestamp": int          # Unix timestamp of save
  }
}
```

## Testing

Integration tests are available in:
- `tests/test_quick_save_integration.gd` - Integration tests for the quick save feature
- `tests/test_save_load.gd` - Unit tests for SaveGameManager

Run tests with:
```bash
cd tests
./run_tests.sh
```

## Usage for Developers

### Manually Trigger a Save

```gdscript
# Update player data
SaveGameManager.update_player_data(
    player.global_position,
    player.rotation.y,
    player.is_first_person
)

# Update day/night data
SaveGameManager.update_day_night_data(
    current_time,
    is_locked_out,
    lockout_end_time,
    time_scale
)

# Write to disk
SaveGameManager.save_game()
```

### Load Saved Data

```gdscript
# Check if save exists
if SaveGameManager.has_save_file():
    # Get saved data
    var player_data = SaveGameManager.get_player_data()
    var day_night_data = SaveGameManager.get_day_night_data()
    
    # Apply to game objects
    player.global_position = player_data["position"]
    player.rotation.y = player_data["rotation_y"]
    current_time = day_night_data["current_time"]
```

### Delete Save File

```gdscript
SaveGameManager.delete_save()
```

## Future Enhancements

Potential improvements to the quick save system:

1. Multiple save slots
2. Save file versioning and migration
3. Compressed save files
4. Cloud save synchronization
5. Save file encryption
6. Manual save/load UI
