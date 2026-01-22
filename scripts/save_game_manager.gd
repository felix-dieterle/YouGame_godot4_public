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
        "is_first_person": false,
        "inventory": {},  # Crystal inventory
        "torch_count": 100,  # Number of torches in inventory
        "selected_item": "torch",  # Currently selected item
        "current_air": 100.0,  # Current air level
        "current_health": 100.0,  # Current health
        "flint_stone_count": 2,  # Number of flint stones in inventory
        "mushroom_count": 0,  # Number of mushrooms in inventory
        "bottle_fill_level": 100.0,  # Drinking bottle fill level (0-100)
        "flashlight_enabled": true  # Flashlight state (default ON)
    },
    "world": {
        "seed": 12345,
        "player_chunk": Vector2i.ZERO,
        "torches": [],  # Placed torches in the world
        "campfires": []  # Placed campfires in the world
    },
    "day_night": {
        "current_time": 0.0,
        "is_locked_out": false,
        "lockout_end_time": 0.0,
        "time_scale": 2.0,  # Default 2.0 to match game logic (faster initial progression)
        "day_count": 1,
        "night_start_time": 0.0
    },
    "settings": {
        "master_volume": 80.0,
        "ruler_visible": true
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

func _ready() -> void:
    # Add to autoload group for easy access
    add_to_group("SaveGameManager")
    
    # Auto-load save data at startup if available
    if has_save_file():
        load_game()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # Save game when window is closed (e.g., alt+F4, clicking X button)
        _auto_save_on_exit()
    elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
        # Android back button - save before potentially exiting
        _auto_save_on_exit()
    elif what == NOTIFICATION_APPLICATION_PAUSED:
        # App is being backgrounded (mobile) - save game state
        _auto_save_on_exit()

func _auto_save_on_exit() -> void:
    # Collect current game state and save it
    var player = get_tree().get_first_node_in_group("Player")
    var world_manager = get_tree().get_first_node_in_group("WorldManager")
    var day_night_cycle = get_tree().get_first_node_in_group("DayNightCycle")
    var ruler = get_tree().get_first_node_in_group("RulerOverlay")
    
    if player:
        var inventory = player.crystal_inventory if "crystal_inventory" in player else {}
        var torch_count = player.torch_count if "torch_count" in player else 100
        var selected_item = player.selected_item if "selected_item" in player else "torch"
        var current_air = player.current_air if "current_air" in player else 100.0
        var current_health = player.current_health if "current_health" in player else 100.0
        var flint_stone_count = player.flint_stone_count if "flint_stone_count" in player else 2
        var mushroom_count = player.mushroom_count if "mushroom_count" in player else 0
        var bottle_fill_level = player.bottle_fill_level if "bottle_fill_level" in player else 100.0
        var flashlight_enabled = player.flashlight_enabled if "flashlight_enabled" in player else true
        update_player_data(
            player.global_position,
            player.rotation.y,
            player.is_first_person if "is_first_person" in player else false,
            inventory,
            torch_count,
            selected_item,
            current_air,
            current_health,
            flint_stone_count,
            mushroom_count,
            bottle_fill_level,
            flashlight_enabled
        )
    
    # Collect all placed torches in the world
    var torches = get_tree().get_nodes_in_group("Torches")
    var torch_positions = []
    for torch in torches:
        torch_positions.append({
            "x": torch.global_position.x,
            "y": torch.global_position.y,
            "z": torch.global_position.z
        })
    
    # Collect all placed campfires in the world
    var campfires = get_tree().get_nodes_in_group("Campfires")
    var campfire_positions = []
    for campfire in campfires:
        campfire_positions.append({
            "x": campfire.global_position.x,
            "y": campfire.global_position.y,
            "z": campfire.global_position.z
        })
    
    if world_manager:
        update_world_data(
            world_manager.WORLD_SEED,
            world_manager.player_chunk,
            torch_positions,
            campfire_positions
        )
    
    if day_night_cycle:
        update_day_night_data(
            day_night_cycle.current_time,
            day_night_cycle.is_locked_out,
            day_night_cycle.lockout_end_time,
            day_night_cycle.time_scale,
            day_night_cycle.day_count,
            day_night_cycle.night_start_time
        )
    
    # Save settings (volume and ruler visibility)
    # Get master volume from audio bus (the source of truth)
    var bus_index = AudioServer.get_bus_index("Master")
    var db_volume = AudioServer.get_bus_volume_db(bus_index)
    var master_volume = db_to_linear(db_volume) * 100.0
    
    # Get ruler visibility
    var ruler_visible = true  # Default
    if ruler and ruler.has_method("get_visible_state"):
        ruler_visible = ruler.get_visible_state()
    
    update_settings_data(master_volume, ruler_visible)
    
    save_game()
    
    # Show save message
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("show_message"):
        ui_manager.show_message("Game saved!", 1.0)
    
    print("SaveGameManager: Auto-save on exit completed")

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
    config.set_value("player", "torch_count", save_data["player"]["torch_count"])
    config.set_value("player", "selected_item", save_data["player"]["selected_item"])
    config.set_value("player", "current_air", save_data["player"]["current_air"])
    config.set_value("player", "current_health", save_data["player"]["current_health"])
    config.set_value("player", "flint_stone_count", save_data["player"]["flint_stone_count"])
    config.set_value("player", "mushroom_count", save_data["player"]["mushroom_count"])
    config.set_value("player", "bottle_fill_level", save_data["player"]["bottle_fill_level"])
    config.set_value("player", "flashlight_enabled", save_data["player"]["flashlight_enabled"])
    
    # Save inventory (convert dictionary to JSON string for easier storage)
    var inventory_json = JSON.stringify(save_data["player"]["inventory"])
    config.set_value("player", "inventory", inventory_json)
    
    # Save world data
    config.set_value("world", "seed", save_data["world"]["seed"])
    config.set_value("world", "player_chunk_x", save_data["world"]["player_chunk"].x)
    config.set_value("world", "player_chunk_y", save_data["world"]["player_chunk"].y)
    
    # Save torch positions as JSON
    var torches_json = JSON.stringify(save_data["world"]["torches"])
    config.set_value("world", "torches", torches_json)
    
    # Save campfire positions as JSON
    var campfires_json = JSON.stringify(save_data["world"]["campfires"])
    config.set_value("world", "campfires", campfires_json)
    
    # Save day/night data
    config.set_value("day_night", "current_time", save_data["day_night"]["current_time"])
    config.set_value("day_night", "is_locked_out", save_data["day_night"]["is_locked_out"])
    config.set_value("day_night", "lockout_end_time", save_data["day_night"]["lockout_end_time"])
    config.set_value("day_night", "time_scale", save_data["day_night"]["time_scale"])
    config.set_value("day_night", "day_count", save_data["day_night"]["day_count"])
    config.set_value("day_night", "night_start_time", save_data["day_night"]["night_start_time"])
    
    # Save settings data
    config.set_value("settings", "master_volume", save_data["settings"]["master_volume"])
    config.set_value("settings", "ruler_visible", save_data["settings"]["ruler_visible"])
    
    # Save metadata
    config.set_value("meta", "version", save_data["meta"]["version"])
    config.set_value("meta", "timestamp", Time.get_unix_time_from_system())
    
    # Update timestamp in save_data for widget export
    save_data["meta"]["timestamp"] = Time.get_unix_time_from_system()
    
    # Write to file
    var error = config.save(SAVE_FILE_PATH)
    if error != OK:
        push_error("SaveGameManager: Failed to save game: " + str(error))
        return false
    
    # Export to Android widget
    if has_node("/root/SaveGameWidgetExporter"):
        get_node("/root/SaveGameWidgetExporter").export_save_data(save_data)
    
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
    save_data["player"]["torch_count"] = config.get_value("player", "torch_count", 100)
    save_data["player"]["selected_item"] = config.get_value("player", "selected_item", "torch")
    save_data["player"]["current_air"] = config.get_value("player", "current_air", 100.0)
    save_data["player"]["current_health"] = config.get_value("player", "current_health", 100.0)
    save_data["player"]["flint_stone_count"] = config.get_value("player", "flint_stone_count", 2)
    save_data["player"]["mushroom_count"] = config.get_value("player", "mushroom_count", 0)
    save_data["player"]["bottle_fill_level"] = config.get_value("player", "bottle_fill_level", 100.0)
    save_data["player"]["flashlight_enabled"] = config.get_value("player", "flashlight_enabled", true)
    
    # Load inventory (parse from JSON string)
    var inventory_json = config.get_value("player", "inventory", "{}")
    var json = JSON.new()
    var parse_result = json.parse(inventory_json)
    if parse_result == OK:
        save_data["player"]["inventory"] = json.data
    else:
        save_data["player"]["inventory"] = {}  # Default to empty inventory if parsing fails
    
    # Load world data
    save_data["world"]["seed"] = config.get_value("world", "seed", 12345)
    var chunk_x = config.get_value("world", "player_chunk_x", 0)
    var chunk_y = config.get_value("world", "player_chunk_y", 0)
    save_data["world"]["player_chunk"] = Vector2i(chunk_x, chunk_y)
    
    # Load torch positions (parse from JSON)
    var torches_json = config.get_value("world", "torches", "[]")
    var torches_parser = JSON.new()
    var torches_parse_result = torches_parser.parse(torches_json)
    if torches_parse_result == OK:
        save_data["world"]["torches"] = torches_parser.data
    else:
        save_data["world"]["torches"] = []
    
    # Load campfire positions (parse from JSON)
    var campfires_json = config.get_value("world", "campfires", "[]")
    var campfires_parser = JSON.new()
    var campfires_parse_result = campfires_parser.parse(campfires_json)
    if campfires_parse_result == OK:
        save_data["world"]["campfires"] = campfires_parser.data
    else:
        save_data["world"]["campfires"] = []
    
    # Load day/night data
    save_data["day_night"]["current_time"] = config.get_value("day_night", "current_time", 0.0)
    save_data["day_night"]["is_locked_out"] = config.get_value("day_night", "is_locked_out", false)
    save_data["day_night"]["lockout_end_time"] = config.get_value("day_night", "lockout_end_time", 0.0)
    save_data["day_night"]["time_scale"] = config.get_value("day_night", "time_scale", 2.0)  # Default 2.0 to match game logic
    save_data["day_night"]["day_count"] = config.get_value("day_night", "day_count", 1)
    save_data["day_night"]["night_start_time"] = config.get_value("day_night", "night_start_time", 0.0)
    
    # Log sleep state information for debugging
    var current_unix_time = Time.get_unix_time_from_system()
    var time_until_lockout_end = save_data["day_night"]["lockout_end_time"] - current_unix_time
    var log_msg = "LOAD - is_locked_out: %s | lockout_end_time: %.2f | current_unix_time: %.2f | time_until_end: %.2f | current_time: %.2f | day_count: %d | night_start_time: %.2f" % [
        str(save_data["day_night"]["is_locked_out"]),
        save_data["day_night"]["lockout_end_time"],
        current_unix_time,
        time_until_lockout_end,
        save_data["day_night"]["current_time"],
        save_data["day_night"]["day_count"],
        save_data["day_night"]["night_start_time"]
    ]
    LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
    
    # Load settings data
    save_data["settings"]["master_volume"] = config.get_value("settings", "master_volume", 80.0)
    save_data["settings"]["ruler_visible"] = config.get_value("settings", "ruler_visible", true)
    
    # Load metadata
    save_data["meta"]["version"] = config.get_value("meta", "version", "1.0")
    save_data["meta"]["timestamp"] = config.get_value("meta", "timestamp", 0)
    
    _data_loaded = true
    print("SaveGameManager: Game loaded successfully from: " + SAVE_FILE_PATH)
    load_completed.emit(true)
    return true

# Update player data for saving
func update_player_data(position: Vector3, rotation_y: float, is_first_person: bool, inventory: Dictionary = {}, torch_count: int = 100, selected_item: String = "torch", current_air: float = 100.0, current_health: float = 100.0, flint_stone_count: int = 2, mushroom_count: int = 0, bottle_fill_level: float = 100.0, flashlight_enabled: bool = true) -> void:
    save_data["player"]["position"] = position
    save_data["player"]["rotation_y"] = rotation_y
    save_data["player"]["is_first_person"] = is_first_person
    save_data["player"]["inventory"] = inventory
    save_data["player"]["torch_count"] = torch_count
    save_data["player"]["selected_item"] = selected_item
    save_data["player"]["current_air"] = current_air
    save_data["player"]["current_health"] = current_health
    save_data["player"]["flint_stone_count"] = flint_stone_count
    save_data["player"]["mushroom_count"] = mushroom_count
    save_data["player"]["bottle_fill_level"] = bottle_fill_level
    save_data["player"]["flashlight_enabled"] = flashlight_enabled

# Update world data for saving
func update_world_data(seed: int, player_chunk: Vector2i, torches: Array = [], campfires: Array = []) -> void:
    save_data["world"]["seed"] = seed
    save_data["world"]["player_chunk"] = player_chunk
    save_data["world"]["torches"] = torches
    save_data["world"]["campfires"] = campfires

# Update day/night data for saving
func update_day_night_data(current_time: float, is_locked_out: bool, lockout_end_time: float, time_scale: float = 2.0, day_count: int = 1, night_start_time: float = 0.0) -> void:
    save_data["day_night"]["current_time"] = current_time
    save_data["day_night"]["is_locked_out"] = is_locked_out
    save_data["day_night"]["lockout_end_time"] = lockout_end_time
    save_data["day_night"]["time_scale"] = time_scale
    save_data["day_night"]["day_count"] = day_count
    save_data["day_night"]["night_start_time"] = night_start_time

# Update settings data for saving
func update_settings_data(master_volume: float, ruler_visible: bool) -> void:
    save_data["settings"]["master_volume"] = master_volume
    save_data["settings"]["ruler_visible"] = ruler_visible

# Get player data
func get_player_data() -> Dictionary:
    return save_data["player"]

# Get world data
func get_world_data() -> Dictionary:
    return save_data["world"]

# Get day/night data
func get_day_night_data() -> Dictionary:
    return save_data["day_night"]

# Get settings data
func get_settings_data() -> Dictionary:
    return save_data["settings"]

# Delete the save file
func delete_save() -> bool:
    if not has_save_file():
        return true
    
    var dir = DirAccess.open("user://")
    if dir:
        var error = dir.remove("game_save.cfg")
        if error == OK:
            _data_loaded = false  # Reset loaded flag
            
            # Clear widget data
            if has_node("/root/SaveGameWidgetExporter"):
                get_node("/root/SaveGameWidgetExporter").clear_widget_data()
            
            print("SaveGameManager: Save file deleted")
            return true
        else:
            push_error("SaveGameManager: Failed to delete save file: " + str(error))
            return false
    return false

# Reset the loaded flag (useful for testing)
func reset_loaded_flag() -> void:
    _data_loaded = false
