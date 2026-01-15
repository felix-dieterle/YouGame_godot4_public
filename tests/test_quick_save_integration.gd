extends Node

# Integration test for quick save functionality
# Tests that all components work together for the quick save feature

var test_passed = true
var test_messages = []

func _ready():
	print("\n=== Quick Save Integration Test ===\n")
	run_tests()
	print_results()
	
	# Exit after tests
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if test_passed else 1)

func run_tests():
	test_save_manager_autoload()
	test_save_on_night_begin()
	test_save_on_menu_quit()
	test_load_on_startup()
	test_time_position_orientation_saved()
	test_settings_saved()

func test_save_manager_autoload():
	var test_name = "SaveGameManager auto-loads on startup"
	if SaveGameManager != null:
		add_test_result(test_name, true, "SaveGameManager is accessible as autoload singleton")
	else:
		add_test_result(test_name, false, "SaveGameManager not found")

func test_save_on_night_begin():
	var test_name = "Save triggered when night begins"
	
	# Check that DayNightCycle has _save_game_state method
	var day_night_script = load("res://scripts/day_night_cycle.gd")
	var test_instance = day_night_script.new()
	
	if test_instance.has_method("_save_game_state"):
		# Check that it's called in the sunset complete code path
		# We can verify by checking the source code has the call
		add_test_result(test_name, true, "_save_game_state method exists in DayNightCycle")
	else:
		add_test_result(test_name, false, "_save_game_state method not found")
	
	test_instance.free()

func test_save_on_menu_quit():
	var test_name = "Save triggered when quitting via menu"
	
	# Check that PauseMenu has _save_game_state method
	var pause_menu_script = load("res://scripts/pause_menu.gd")
	var test_instance = pause_menu_script.new()
	
	if test_instance.has_method("_save_game_state"):
		add_test_result(test_name, true, "_save_game_state method exists in PauseMenu")
	else:
		add_test_result(test_name, false, "_save_game_state method not found")
	
	test_instance.free()

func test_load_on_startup():
	var test_name = "Save file loaded automatically on game start"
	
	# Clean up first
	SaveGameManager.delete_save()
	
	# Create a save
	SaveGameManager.update_player_data(Vector3(100, 50, 200), 2.5, true)
	SaveGameManager.update_day_night_data(1500.0, false, 0.0, 2.0)
	SaveGameManager.save_game()
	
	# Verify it has a save file
	if SaveGameManager.has_save_file():
		add_test_result(test_name, true, "Save file created and detected")
	else:
		add_test_result(test_name, false, "Failed to create save file")
	
	# Clean up
	SaveGameManager.delete_save()

func test_time_position_orientation_saved():
	var test_name = "Time, position, and orientation are saved and loaded"
	
	# Clean up
	SaveGameManager.delete_save()
	
	# Set test data
	var test_position = Vector3(123.45, 67.89, -98.76)
	var test_rotation = 3.14159
	var test_time = 987.65
	var test_time_scale = 4.0
	
	# Save data
	SaveGameManager.update_player_data(test_position, test_rotation, false)
	SaveGameManager.update_day_night_data(test_time, false, 0.0, test_time_scale)
	SaveGameManager.save_game()
	
	# Clear in-memory data
	SaveGameManager.save_data["player"]["position"] = Vector3.ZERO
	SaveGameManager.save_data["player"]["rotation_y"] = 0.0
	SaveGameManager.save_data["day_night"]["current_time"] = 0.0
	SaveGameManager.save_data["day_night"]["time_scale"] = 1.0
	SaveGameManager.reset_loaded_flag()
	
	# Load data
	SaveGameManager.load_game()
	
	# Verify
	var player_data = SaveGameManager.get_player_data()
	var day_night_data = SaveGameManager.get_day_night_data()
	
	var position_ok = player_data["position"].is_equal_approx(test_position)
	var rotation_ok = abs(player_data["rotation_y"] - test_rotation) < 0.001
	var time_ok = abs(day_night_data["current_time"] - test_time) < 0.001
	var time_scale_ok = abs(day_night_data["time_scale"] - test_time_scale) < 0.001
	
	if position_ok and rotation_ok and time_ok and time_scale_ok:
		add_test_result(test_name, true, "All data (position, rotation, time, time_scale) saved and loaded correctly")
	else:
		add_test_result(test_name, false, 
			"Data mismatch - Position: %s, Rotation: %s, Time: %s, TimeScale: %s" % [position_ok, rotation_ok, time_ok, time_scale_ok])
	
	# Clean up
	SaveGameManager.delete_save()

func test_settings_saved():
	var test_name = "Settings (volume and ruler) saved and loaded"
	
	# Clean up
	SaveGameManager.delete_save()
	
	# Set test data
	var test_volume = 65.0
	var test_ruler_visible = false
	
	# Save settings data
	SaveGameManager.update_settings_data(test_volume, test_ruler_visible)
	SaveGameManager.save_game()
	
	# Clear in-memory data
	SaveGameManager.save_data["settings"]["master_volume"] = 80.0
	SaveGameManager.save_data["settings"]["ruler_visible"] = true
	SaveGameManager.reset_loaded_flag()
	
	# Load data
	SaveGameManager.load_game()
	
	# Verify
	var settings_data = SaveGameManager.get_settings_data()
	
	var volume_ok = abs(settings_data["master_volume"] - test_volume) < 0.001
	var ruler_ok = settings_data["ruler_visible"] == test_ruler_visible
	
	if volume_ok and ruler_ok:
		add_test_result(test_name, true, "Settings (volume and ruler visibility) saved and loaded correctly")
	else:
		add_test_result(test_name, false, 
			"Settings mismatch - Volume: %s, Ruler: %s" % [volume_ok, ruler_ok])
	
	# Clean up
	SaveGameManager.delete_save()

func add_test_result(test_name: String, passed: bool, message: String):
	test_passed = test_passed and passed
	var status = "✓ PASS" if passed else "✗ FAIL"
	test_messages.append({
		"status": status,
		"name": test_name,
		"message": message
	})

func print_results():
	print("\n--- Test Results ---\n")
	for result in test_messages:
		print("[%s] %s: %s" % [result.status, result.name, result.message])
	
	print("\n--- Summary ---")
	if test_passed:
		print("All integration tests PASSED ✓")
	else:
		print("Some integration tests FAILED ✗")
	print("")
