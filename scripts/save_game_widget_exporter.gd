extends Node
# SaveGameWidgetExporter - Exports save data to Android widget
# This autoload singleton interfaces with the Android SaveGameWidget plugin

var _android_plugin = null

func _ready() -> void:
	# Initialize Android plugin if running on Android
	if OS.get_name() == "Android":
		if Engine.has_singleton("SaveGameWidget"):
			_android_plugin = Engine.get_singleton("SaveGameWidget")
			print("SaveGameWidgetExporter: Android plugin initialized")
		else:
			push_warning("SaveGameWidgetExporter: SaveGameWidget plugin not found")
	else:
		print("SaveGameWidgetExporter: Not running on Android, widget export disabled")

# Export save data to the Android widget
func export_save_data(save_data: Dictionary) -> void:
	if _android_plugin == null:
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
	
	# Call Android plugin method
	# Note: position.y is included for future debugging features (e.g., cave detection)
	# but is not currently displayed in the widget
	_android_plugin.exportSaveData(
		timestamp,
		day_count,
		current_health,
		torch_count,
		position.x,
		position.y,
		position.z
	)
	
	print("SaveGameWidgetExporter: Exported save data to widget")

# Clear widget data
func clear_widget_data() -> void:
	if _android_plugin == null:
		return
	
	_android_plugin.clearSaveData()
	print("SaveGameWidgetExporter: Cleared widget data")
