# Utility Systems

Data management, persistence, and helper systems.

## Files

### Save Game Manager (`save_game_manager.gd`)
- **Autoload singleton** - globally accessible
- Save/load game state to JSON
- Saves to: `user://savegame.json`
- Includes: player position, camera mode, world seed
- Version compatibility checking

### Log Export Manager (`log_export_manager.gd`)
- **Autoload singleton** - globally accessible
- Export debug logs to files
- Log file management
- Download/share functionality

### Save Game Widget Exporter (`save_game_widget_exporter.gd`)
- **Autoload singleton** - globally accessible
- Android home screen widget integration
- Exports save game metrics
- Updates widget with game data

## Usage

```gdscript
# Save Game Manager (autoload)
SaveGameManager.save_game()
SaveGameManager.load_game()

# Log Export Manager (autoload)
LogExportManager.export_logs()

# Widget Exporter (autoload)
SaveGameWidgetExporter.update_widget_data()
```

## Integration

- All three are autoload singletons
- SaveGameManager is called by UI/pause menu
- LogExportManager integrates with DebugLogOverlay
- Widget exporter updates on save events

## Save Data Format

```json
{
  "version": "1.0.144",
  "player_position": {"x": 0, "y": 0, "z": 0},
  "camera_mode": "third_person",
  "world_seed": 12345
}
```
