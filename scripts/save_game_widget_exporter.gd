extends Node
# SaveGameWidgetExporter - Exports save data to Android widget
# This autoload singleton writes save data to a shared file for the widget app to read

# Shared file path - accessible by the standalone widget app
# On Android, this will be in external files directory
var widget_data_path: String = ""

func _ready() -> void:
	if OS.get_name() == "Android":
		# Use external storage for cross-app access
		# This requires READ_EXTERNAL_STORAGE permission in widget app
		widget_data_path = "/storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt"
		print("SaveGameWidgetExporter: Android detected, file-based widget export enabled")
		print("SaveGameWidgetExporter: Widget data path: ", widget_data_path)
	else:
		print("SaveGameWidgetExporter: Not running on Android, widget export disabled")

# Export save data to the Android widget
func export_save_data(save_data: Dictionary) -> void:
	if OS.get_name() != "Android" or widget_data_path == "":
		return
	
	# Extract metadata
	var timestamp = save_data.get("meta", {}).get("timestamp", 0)
	
	# Extract day/night data
	var day_night = save_data.get("day_night", {})
	var day_count = day_night.get("day_count", 1)
	
	# Extract player data
	var player = save_data.get("player", {})
	var current_health = player.get("current_health", 100.0)
	var torch_count = player.get("torch_count", 0)
	var position = player.get("position", Vector3.ZERO)
	
	# Write data to shared file in simple key=value format
	var file = FileAccess.open(widget_data_path, FileAccess.WRITE)
	if file:
		file.store_line("timestamp=" + str(timestamp))
		file.store_line("day_count=" + str(day_count))
		file.store_line("current_health=" + str(current_health))
		file.store_line("torch_count=" + str(torch_count))
		file.store_line("position_x=" + str(position.x))
		file.store_line("position_z=" + str(position.z))
		file.close()
		
		print("SaveGameWidgetExporter: Exported save data to file for widget: ", widget_data_path)
	else:
		push_error("SaveGameWidgetExporter: Failed to write widget data file: " + widget_data_path)

# Clear widget data
func clear_widget_data() -> void:
	if OS.get_name() != "Android" or widget_data_path == "":
		return
	
	# Delete the widget data file
	if FileAccess.file_exists(widget_data_path):
		DirAccess.remove_absolute(widget_data_path)
		print("SaveGameWidgetExporter: Cleared widget data")
