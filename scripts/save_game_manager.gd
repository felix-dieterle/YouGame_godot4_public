extends Node
# SaveGameManager - Singleton for save/load functionality

# This manager handles saving and loading game state in a performant way

# Save file path - stored in user directory
const SAVE_FILE_PATH: String = "user://game_save.cfg"

# Save data structure
var save_data: Dictionary = {
    "player": {
        "position": Vector3.ZERO,
        "rotation_y": 0.0,
        "is_first_person": false
    },
    "world": {
        "seed": 12345,
        "player_chunk": Vector2i.ZERO
    },
    "day_night": {
        "current_time": 0.0,
        "is_locked_out": false,
        "lockout_end_time": 0.0,
        "time_scale": 1.0
    },
    "meta": {
        "version": "1.0",
        "timestamp": 0
    }
}

# Signals
signal save_completed
signal load_completed(success: bool)

# Track if data has been loaded to avoid duplicate loads
var _data_loaded: bool = false

func _ready():
    # Add to autoload group for easy access
    add_to_group("SaveGameManager")
    
    # Auto-load save data at startup if available
    if has_save_file():
        load_game()

# Check if a save file exists
func has_save_file() -> bool:
    return FileAccess.file_exists(SAVE_FILE_PATH)

# Save the current game state
# This is performant using ConfigFile which is optimized for key-value storage
func save_game() -> bool:
    var config = ConfigFile.new()
    
    # Save player data
    config.set_value("player", "position_x", save_data["player"]["position"].x)
    config.set_value("player", "position_y", save_data["player"]["position"].y)
    config.set_value("player", "position_z", save_data["player"]["position"].z)
    config.set_value("player", "rotation_y", save_data["player"]["rotation_y"])
    config.set_value("player", "is_first_person", save_data["player"]["is_first_person"])
    
    # Save world data
    config.set_value("world", "seed", save_data["world"]["seed"])
    config.set_value("world", "player_chunk_x", save_data["world"]["player_chunk"].x)
    config.set_value("world", "player_chunk_y", save_data["world"]["player_chunk"].y)
    
    # Save day/night data
    config.set_value("day_night", "current_time", save_data["day_night"]["current_time"])
    config.set_value("day_night", "is_locked_out", save_data["day_night"]["is_locked_out"])
    config.set_value("day_night", "lockout_end_time", save_data["day_night"]["lockout_end_time"])
    config.set_value("day_night", "time_scale", save_data["day_night"]["time_scale"])
    
    # Save metadata
    config.set_value("meta", "version", save_data["meta"]["version"])
    config.set_value("meta", "timestamp", Time.get_unix_time_from_system())
    
    # Write to file
    var error = config.save(SAVE_FILE_PATH)
    if error != OK:
        push_error("SaveGameManager: Failed to save game: " + str(error))
        return false
    
    print("SaveGameManager: Game saved successfully to: " + SAVE_FILE_PATH)
    save_completed.emit()
    return true

# Load the game state from file
func load_game() -> bool:
    # Avoid loading multiple times
    if _data_loaded:
        print("SaveGameManager: Data already loaded, skipping")
        return true
    
    if not has_save_file():
        push_warning("SaveGameManager: No save file found")
        load_completed.emit(false)
        return false
    
    var config = ConfigFile.new()
    var error = config.load(SAVE_FILE_PATH)
    
    if error != OK:
        push_error("SaveGameManager: Failed to load game: " + str(error))
        load_completed.emit(false)
        return false
    
    # Load player data
    var pos_x = config.get_value("player", "position_x", 0.0)
    var pos_y = config.get_value("player", "position_y", 0.0)
    var pos_z = config.get_value("player", "position_z", 0.0)
    save_data["player"]["position"] = Vector3(pos_x, pos_y, pos_z)
    save_data["player"]["rotation_y"] = config.get_value("player", "rotation_y", 0.0)
    save_data["player"]["is_first_person"] = config.get_value("player", "is_first_person", false)
    
    # Load world data
    save_data["world"]["seed"] = config.get_value("world", "seed", 12345)
    var chunk_x = config.get_value("world", "player_chunk_x", 0)
    var chunk_y = config.get_value("world", "player_chunk_y", 0)
    save_data["world"]["player_chunk"] = Vector2i(chunk_x, chunk_y)
    
    # Load day/night data
    save_data["day_night"]["current_time"] = config.get_value("day_night", "current_time", 0.0)
    save_data["day_night"]["is_locked_out"] = config.get_value("day_night", "is_locked_out", false)
    save_data["day_night"]["lockout_end_time"] = config.get_value("day_night", "lockout_end_time", 0.0)
    save_data["day_night"]["time_scale"] = config.get_value("day_night", "time_scale", 1.0)
    
    # Load metadata
    save_data["meta"]["version"] = config.get_value("meta", "version", "1.0")
    save_data["meta"]["timestamp"] = config.get_value("meta", "timestamp", 0)
    
    _data_loaded = true
    print("SaveGameManager: Game loaded successfully from: " + SAVE_FILE_PATH)
    load_completed.emit(true)
    return true

# Update player data for saving
func update_player_data(position: Vector3, rotation_y: float, is_first_person: bool):
    save_data["player"]["position"] = position
    save_data["player"]["rotation_y"] = rotation_y
    save_data["player"]["is_first_person"] = is_first_person

# Update world data for saving
func update_world_data(seed: int, player_chunk: Vector2i):
    save_data["world"]["seed"] = seed
    save_data["world"]["player_chunk"] = player_chunk

# Update day/night data for saving
func update_day_night_data(current_time: float, is_locked_out: bool, lockout_end_time: float, time_scale: float = 1.0):
    save_data["day_night"]["current_time"] = current_time
    save_data["day_night"]["is_locked_out"] = is_locked_out
    save_data["day_night"]["lockout_end_time"] = lockout_end_time
    save_data["day_night"]["time_scale"] = time_scale

# Get player data
func get_player_data() -> Dictionary:
    return save_data["player"]

# Get world data
func get_world_data() -> Dictionary:
    return save_data["world"]

# Get day/night data
func get_day_night_data() -> Dictionary:
    return save_data["day_night"]

# Delete the save file
func delete_save() -> bool:
    if not has_save_file():
        return true
    
    var dir = DirAccess.open("user://")
    if dir:
        var error = dir.remove("game_save.cfg")
        if error == OK:
            _data_loaded = false  # Reset loaded flag
            print("SaveGameManager: Save file deleted")
            return true
        else:
            push_error("SaveGameManager: Failed to delete save file: " + str(error))
            return false
    return false
