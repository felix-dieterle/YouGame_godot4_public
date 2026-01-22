extends Node

# Test script for ZIP export functionality
# This test will create sample logs and export them to a ZIP file

func _ready():
	print("=== Testing Log Export ZIP Functionality ===")
	
	# Wait for autoloads to be ready
	await get_tree().process_frame
	
	# Add test logs
	_add_test_logs()
	
	# Export to ZIP
	var zip_path = LogExportManager.export_all_logs_as_zip()
	
	if zip_path != "":
		print("✓ ZIP export successful: %s" % zip_path)
		
		# Verify the file exists
		if FileAccess.file_exists(zip_path):
			print("✓ ZIP file exists")
			
			# Get file size
			var file = FileAccess.open(zip_path, FileAccess.READ)
			if file:
				var size = file.get_length()
				file.close()
				print("✓ ZIP file size: %d bytes" % size)
				
				# Verify it's a valid ZIP (starts with PK)
				file = FileAccess.open(zip_path, FileAccess.READ)
				var magic = file.get_buffer(2)
				file.close()
				if magic[0] == 0x50 and magic[1] == 0x4B:  # "PK" signature
					print("✓ ZIP file has valid magic signature")
				else:
					print("✗ ZIP file has invalid magic signature")
			else:
				print("✗ Could not open ZIP file")
		else:
			print("✗ ZIP file does not exist")
		
		# Print log counts
		print("\nLog Counts:")
		print("  Sun Lighting: %d" % LogExportManager.get_log_count(LogExportManager.LogType.SUN_LIGHTING_ISSUE))
		print("  Sleep State: %d" % LogExportManager.get_log_count(LogExportManager.LogType.SLEEP_STATE_ISSUE))
		print("  Error Logs: %d" % LogExportManager.get_log_count(LogExportManager.LogType.ERROR_LOGS))
		
		print("\n=== Test Complete ===")
		print("Check the log file at: %s" % zip_path)
		print("On Linux: ~/.local/share/godot/app_userdata/YouGame/logs/")
		print("On Windows: %%APPDATA%%\\Godot\\app_userdata\\YouGame\\logs\\")
	else:
		print("✗ ZIP export failed")
	
	# Exit after 1 second
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func _add_test_logs():
	print("\nAdding test logs...")
	
	# Add sun lighting logs
	for i in range(5):
		LogExportManager.add_log(
			LogExportManager.LogType.SUN_LIGHTING_ISSUE,
			"Test sun log %d - Sun Position: %.1f° | Light Energy: %.2f" % [i, 85.0 + i * 10, 2.0 + i * 0.5]
		)
	
	# Add sleep state logs
	for i in range(3):
		LogExportManager.add_log(
			LogExportManager.LogType.SLEEP_STATE_ISSUE,
			"Test sleep log %d - is_locked_out: true | day_count: %d" % [i, i + 1]
		)
	
	# Add error logs
	for i in range(4):
		LogExportManager.add_error("Test error %d - This is a test error message" % i)
	
	print("✓ Added test logs")
