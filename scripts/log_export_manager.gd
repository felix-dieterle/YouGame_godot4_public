extends Node
# Log Export Manager - Collects and exports different types of debug logs
# Used as an autoload singleton

# Log categories
enum LogType {
	SUN_LIGHTING_ISSUE,    # Logs for sun degree lighting problem
	SLEEP_STATE_ISSUE,      # Logs for sleep state after loading save
	GENERAL_DEBUG,          # General debug logs
	ERROR_LOGS              # Error logs from push_error and errors
}

# Storage for different log types
var sun_lighting_logs: Array[String] = []
var sleep_state_logs: Array[String] = []
var general_logs: Array[String] = []
var error_logs: Array[String] = []

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
		LogType.ERROR_LOGS:
			error_logs.append(formatted_msg)
			if error_logs.size() > MAX_LOGS_PER_CATEGORY:
				error_logs.remove_at(0)
	
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
		LogType.ERROR_LOGS:
			return "ERROR"
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
		LogType.ERROR_LOGS:
			logs_array = error_logs
			filename = "error_logs_%s.log" % Time.get_datetime_string_from_system().replace(":", "-")
	
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
		LogType.ERROR_LOGS:
			return error_logs.size()
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
		LogType.ERROR_LOGS:
			error_logs.clear()
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
		LogType.ERROR_LOGS:
			return error_logs.duplicate()
	return []

# Helper function to add an error log entry
static func add_error(message: String) -> void:
	add_log(LogType.ERROR_LOGS, message)

# Export all logs as a ZIP file
static func export_all_logs_as_zip() -> String:
	if instance:
		return instance._export_all_logs_as_zip_internal()
	return ""

func _export_all_logs_as_zip_internal() -> String:
	_ensure_log_directory()
	
	var timestamp_str = Time.get_datetime_string_from_system().replace(":", "-")
	var zip_filename = "yougame_debug_logs_%s.zip" % timestamp_str
	var zip_path = EXPORT_BASE_PATH + zip_filename
	
	# Create ZIP packer
	var packer = ZIPPacker.new()
	var err = packer.open(zip_path)
	
	if err != OK:
		push_error("Failed to create ZIP file: %s (Error: %d)" % [zip_path, err])
		return ""
	
	# Export each log type to the ZIP
	var log_types = [
		{"type": LogType.SUN_LIGHTING_ISSUE, "filename": "1_sun_lighting_issue.log", "logs": sun_lighting_logs},
		{"type": LogType.SLEEP_STATE_ISSUE, "filename": "2_sleep_state_issue.log", "logs": sleep_state_logs},
		{"type": LogType.ERROR_LOGS, "filename": "3_error_logs.log", "logs": error_logs},
		{"type": LogType.GENERAL_DEBUG, "filename": "4_general_debug.log", "logs": general_logs}
	]
	
	for log_info in log_types:
		var log_type = log_info["type"]
		var filename = log_info["filename"]
		var logs_array = log_info["logs"]
		
		# Create file header
		var header = "=== YouGame Debug Logs ===\n"
		header += "Log Type: %s\n" % _get_log_type_name(log_type)
		header += "Export Time: %s\n" % Time.get_datetime_string_from_system()
		header += "Total Entries: %d\n" % logs_array.size()
		header += "Game Version: %s\n" % ProjectSettings.get_setting("application/config/version", "unknown")
		header += "================================\n\n"
		
		var content = header + "\n".join(logs_array)
		
		# Add to ZIP
		packer.start_file(filename)
		packer.write_file(content.to_utf8_buffer())
		packer.close_file()
	
	# Add metadata file with system information
	var metadata = _generate_metadata()
	packer.start_file("0_metadata.txt")
	packer.write_file(metadata.to_utf8_buffer())
	packer.close_file()
	
	# Close the ZIP
	packer.close()
	
	print("All logs exported to ZIP: %s" % zip_path)
	return zip_path

# Generate metadata file content
func _generate_metadata() -> String:
	var metadata = "=== YouGame Debug Logs - System Information ===\n\n"
	metadata += "Export Time: %s\n" % Time.get_datetime_string_from_system()
	metadata += "Game Version: %s\n" % ProjectSettings.get_setting("application/config/version", "unknown")
	metadata += "\n--- Log Counts ---\n"
	metadata += "Sun Lighting Issue Logs: %d\n" % sun_lighting_logs.size()
	metadata += "Sleep State Issue Logs: %d\n" % sleep_state_logs.size()
	metadata += "Error Logs: %d\n" % error_logs.size()
	metadata += "General Debug Logs: %d\n" % general_logs.size()
	metadata += "\n--- System Information ---\n"
	metadata += "OS: %s\n" % OS.get_name()
	metadata += "Processor: %s (%d cores)\n" % [OS.get_processor_name(), OS.get_processor_count()]
	metadata += "Video Adapter: %s\n" % RenderingServer.get_video_adapter_name()
	metadata += "Screen Size: %s\n" % str(DisplayServer.screen_get_size())
	metadata += "Locale: %s\n" % OS.get_locale()
	metadata += "\n--- Description ---\n"
	metadata += "1_sun_lighting_issue.log: Useful data about the brightness/sun problem\n"
	metadata += "2_sleep_state_issue.log: Debug info for game state after reloading during sleep time\n"
	metadata += "3_error_logs.log: Error messages and exceptions\n"
	metadata += "4_general_debug.log: General debug messages and diagnostics\n"
	metadata += "\n==============================================\n"
	return metadata

# Helper function to format sleep state log message
static func format_sleep_state_log(prefix: String, is_locked_out: bool, lockout_end_time: float, current_time: float, day_count: int, night_start_time: float) -> String:
	var current_unix_time = Time.get_unix_time_from_system()
	var time_until_lockout_end = lockout_end_time - current_unix_time
	return "%s - is_locked_out: %s | lockout_end_time: %.2f | current_unix_time: %.2f | time_until_end: %.2f | current_time: %.2f | day_count: %d | night_start_time: %.2f" % [
		prefix,
		str(is_locked_out),
		lockout_end_time,
		current_unix_time,
		time_until_lockout_end,
		current_time,
		day_count,
		night_start_time
	]
