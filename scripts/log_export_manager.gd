extends Node
# Log Export Manager - Collects and exports different types of debug logs
# Used as an autoload singleton

# Log categories
enum LogType {
	SUN_LIGHTING_ISSUE,    # Logs for sun degree lighting problem
	SLEEP_STATE_ISSUE,      # Logs for sleep state after loading save
	GENERAL_DEBUG           # General debug logs
}

# Storage for different log types
var sun_lighting_logs: Array[String] = []
var sleep_state_logs: Array[String] = []
var general_logs: Array[String] = []

# Maximum logs per category
const MAX_LOGS_PER_CATEGORY: int = 500

# File paths for exports
const EXPORT_BASE_PATH: String = "user://logs/"

# Singleton instance
static var instance = null

func _ready() -> void:
	instance = self
	_ensure_log_directory()

# Ensure the log directory exists
func _ensure_log_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("logs"):
			dir.make_dir("logs")

# Add a log entry to a specific category
static func add_log(log_type: LogType, message: String) -> void:
	if instance:
		instance._add_log_internal(log_type, message)

func _add_log_internal(log_type: LogType, message: String) -> void:
	var timestamp = Time.get_datetime_string_from_system()
	var formatted_msg = "[%s] %s" % [timestamp, message]
	
	match log_type:
		LogType.SUN_LIGHTING_ISSUE:
			sun_lighting_logs.append(formatted_msg)
			if sun_lighting_logs.size() > MAX_LOGS_PER_CATEGORY:
				sun_lighting_logs.remove_at(0)
		LogType.SLEEP_STATE_ISSUE:
			sleep_state_logs.append(formatted_msg)
			if sleep_state_logs.size() > MAX_LOGS_PER_CATEGORY:
				sleep_state_logs.remove_at(0)
		LogType.GENERAL_DEBUG:
			general_logs.append(formatted_msg)
			if general_logs.size() > MAX_LOGS_PER_CATEGORY:
				general_logs.remove_at(0)
	
	# Also log to console for immediate visibility
	print("[LOG_EXPORT][%s] %s" % [_get_log_type_name(log_type), message])

# Get the name of a log type
func _get_log_type_name(log_type: LogType) -> String:
	match log_type:
		LogType.SUN_LIGHTING_ISSUE:
			return "SUN_LIGHTING"
		LogType.SLEEP_STATE_ISSUE:
			return "SLEEP_STATE"
		LogType.GENERAL_DEBUG:
			return "GENERAL"
	return "UNKNOWN"

# Export logs of a specific type to a file
static func export_logs(log_type: LogType) -> String:
	if instance:
		return instance._export_logs_internal(log_type)
	return ""

func _export_logs_internal(log_type: LogType) -> String:
	_ensure_log_directory()
	
	var logs_array: Array[String] = []
	var filename: String = ""
	
	match log_type:
		LogType.SUN_LIGHTING_ISSUE:
			logs_array = sun_lighting_logs
			filename = "sun_lighting_issue_%s.log" % Time.get_datetime_string_from_system().replace(":", "-")
		LogType.SLEEP_STATE_ISSUE:
			logs_array = sleep_state_logs
			filename = "sleep_state_issue_%s.log" % Time.get_datetime_string_from_system().replace(":", "-")
		LogType.GENERAL_DEBUG:
			logs_array = general_logs
			filename = "general_debug_%s.log" % Time.get_datetime_string_from_system().replace(":", "-")
	
	var filepath = EXPORT_BASE_PATH + filename
	
	# Create file header
	var header = "=== YouGame Debug Logs ===\n"
	header += "Log Type: %s\n" % _get_log_type_name(log_type)
	header += "Export Time: %s\n" % Time.get_datetime_string_from_system()
	header += "Total Entries: %d\n" % logs_array.size()
	header += "Game Version: %s\n" % ProjectSettings.get_setting("application/config/version", "unknown")
	header += "================================\n\n"
	
	var content = header + "\n".join(logs_array)
	
	# Write to file
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("Logs exported to: %s" % filepath)
		return filepath
	else:
		push_error("Failed to export logs to: %s" % filepath)
		return ""

# Get the number of logs in a category
static func get_log_count(log_type: LogType) -> int:
	if instance:
		return instance._get_log_count_internal(log_type)
	return 0

func _get_log_count_internal(log_type: LogType) -> int:
	match log_type:
		LogType.SUN_LIGHTING_ISSUE:
			return sun_lighting_logs.size()
		LogType.SLEEP_STATE_ISSUE:
			return sleep_state_logs.size()
		LogType.GENERAL_DEBUG:
			return general_logs.size()
	return 0

# Clear logs of a specific type
static func clear_logs(log_type: LogType) -> void:
	if instance:
		instance._clear_logs_internal(log_type)

func _clear_logs_internal(log_type: LogType) -> void:
	match log_type:
		LogType.SUN_LIGHTING_ISSUE:
			sun_lighting_logs.clear()
		LogType.SLEEP_STATE_ISSUE:
			sleep_state_logs.clear()
		LogType.GENERAL_DEBUG:
			general_logs.clear()
	print("Cleared logs for: %s" % _get_log_type_name(log_type))

# Get all logs of a specific type
static func get_logs(log_type: LogType) -> Array[String]:
	if instance:
		return instance._get_logs_internal(log_type)
	return []

func _get_logs_internal(log_type: LogType) -> Array[String]:
	match log_type:
		LogType.SUN_LIGHTING_ISSUE:
			return sun_lighting_logs.duplicate()
		LogType.SLEEP_STATE_ISSUE:
			return sleep_state_logs.duplicate()
		LogType.GENERAL_DEBUG:
			return general_logs.duplicate()
	return []
