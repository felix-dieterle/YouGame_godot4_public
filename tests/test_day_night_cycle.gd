extends Node

# Test for DayNightCycle system
const DayNightCycle = preload("res://scripts/day_night_cycle.gd")

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting DayNightCycle Tests ===")
	
	# Run tests
	test_day_cycle_constants()
	test_time_progression()
	test_save_load_state()
	test_warning_timings()
	test_celestial_objects()
	test_time_scale()  # New test for time scale control
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_day_cycle_constants():
	print("\n--- Test: Day Cycle Constants ---")
	
	# Verify constants are set correctly
	assert_equal(DayNightCycle.DAY_CYCLE_DURATION, 30.0 * 60.0, "Day cycle should be 30 minutes")
	assert_equal(DayNightCycle.SUNRISE_DURATION, 60.0, "Sunrise should be 1 minute")
	assert_equal(DayNightCycle.SUNSET_DURATION, 60.0, "Sunset should be 1 minute")
	assert_equal(DayNightCycle.SLEEP_LOCKOUT_DURATION, 4.0 * 60.0 * 60.0, "Lockout should be 4 hours")
	assert_equal(DayNightCycle.WARNING_TIME_2MIN, 2.0 * 60.0, "2-minute warning time")
	assert_equal(DayNightCycle.WARNING_TIME_1MIN, 1.0 * 60.0, "1-minute warning time")

func test_time_progression():
	print("\n--- Test: Time Progression ---")
	
	# Create a temporary scene with required nodes
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	# Add mock world environment
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	# Add day/night cycle
	test_scene.add_child(day_night)
	
	# Test initial state
	assert_equal(day_night.current_time, 0.0, "Initial time should be 0")
	assert_equal(day_night.is_night, false, "Should start as day")
	assert_equal(day_night.is_locked_out, false, "Should not be locked out initially")
	
	# Cleanup
	test_scene.queue_free()

func test_save_load_state():
	print("\n--- Test: Save/Load State ---")
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	test_scene.add_child(day_night)
	
	# Set some state
	day_night.is_locked_out = true
	day_night.lockout_end_time = 1000000.0
	day_night.current_time = 500.0
	
	# Save state
	day_night._save_state()
	
	# Create new instance and load
	var day_night2 = DayNightCycle.new()
	test_scene.add_child(day_night2)
	day_night2._load_state()
	
	# Verify loaded state
	assert_equal(day_night2.is_locked_out, true, "Lockout state should be saved")
	assert_equal(day_night2.lockout_end_time, 1000000.0, "Lockout end time should be saved")
	assert_equal(day_night2.current_time, 500.0, "Current time should be saved")
	
	# Cleanup
	test_scene.queue_free()
	
	# Clean up save file
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("day_night_save.cfg")

func test_warning_timings():
	print("\n--- Test: Warning Timings ---")
	
	# Test that warnings appear at the right time
	var warning_2min = DayNightCycle.WARNING_TIME_2MIN
	var warning_1min = DayNightCycle.WARNING_TIME_1MIN
	var day_duration = DayNightCycle.DAY_CYCLE_DURATION
	
	# 2-minute warning should trigger at day_duration - 2min
	var trigger_time_2min = day_duration - warning_2min
	assert_true(trigger_time_2min > 0, "2-minute warning time should be positive")
	assert_true(trigger_time_2min < day_duration, "2-minute warning should be before end of day")
	
	# 1-minute warning should trigger at day_duration - 1min
	var trigger_time_1min = day_duration - warning_1min
	assert_true(trigger_time_1min > trigger_time_2min, "1-minute warning should come after 2-minute warning")
	assert_true(trigger_time_1min < day_duration, "1-minute warning should be before end of day")

func test_celestial_objects():
	print("\n--- Test: Celestial Objects ---")
	
	# In headless mode, celestial objects are not created
	# This is expected behavior, so we just verify the functions exist
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light and environment
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	test_scene.add_child(day_night)
	
	# Verify functions are callable
	assert_true(day_night.has_method("_create_sun"), "Should have _create_sun method")
	assert_true(day_night.has_method("_create_moon"), "Should have _create_moon method")
	assert_true(day_night.has_method("_create_stars"), "Should have _create_stars method")
	assert_true(day_night.has_method("_update_sun_position"), "Should have _update_sun_position method")
	assert_true(day_night.has_method("_update_moon_position"), "Should have _update_moon_position method")
	assert_true(day_night.has_method("_update_stars_visibility"), "Should have _update_stars_visibility method")
	
	# In headless mode, objects should be null
	# But we can still verify the variables exist
	assert_true("sun" in day_night, "Should have sun variable")
	assert_true("moon" in day_night, "Should have moon variable")
	assert_true("stars" in day_night, "Should have stars variable")
	
	# Cleanup
	test_scene.queue_free()

func test_time_scale():
	print("\n--- Test: Time Scale Control ---")
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light and environment
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	test_scene.add_child(day_night)
	
	# Test initial time scale
	assert_equal(day_night.time_scale, 1.0, "Initial time scale should be 1.0")
	
	# Test increase
	day_night.increase_time_scale()
	assert_equal(day_night.time_scale, 2.0, "Time scale should double to 2.0")
	
	day_night.increase_time_scale()
	assert_equal(day_night.time_scale, 4.0, "Time scale should double to 4.0")
	
	day_night.increase_time_scale()
	assert_equal(day_night.time_scale, 8.0, "Time scale should double to 8.0")
	
	# Test max limit
	day_night.increase_time_scale()
	day_night.increase_time_scale()
	day_night.increase_time_scale()
	assert_equal(day_night.time_scale, 32.0, "Time scale should cap at 32.0")
	
	# Reset to 1.0
	day_night.time_scale = 1.0
	
	# Test decrease
	day_night.decrease_time_scale()
	assert_equal(day_night.time_scale, 0.5, "Time scale should halve to 0.5")
	
	day_night.decrease_time_scale()
	assert_equal(day_night.time_scale, 0.25, "Time scale should halve to 0.25")
	
	# Test min limit
	day_night.decrease_time_scale()
	assert_equal(day_night.time_scale, 0.25, "Time scale should cap at 0.25")
	
	# Verify functions exist
	assert_true(day_night.has_method("increase_time_scale"), "Should have increase_time_scale method")
	assert_true(day_night.has_method("decrease_time_scale"), "Should have decrease_time_scale method")
	
	# Cleanup
	test_scene.queue_free()

# Helper functions
func assert_equal(actual, expected, message: String):
	if actual == expected:
		print("  ✓ PASS: ", message)
		test_passed += 1
	else:
		print("  ✗ FAIL: ", message, " (expected: ", expected, ", got: ", actual, ")")
		test_failed += 1

func assert_true(condition: bool, message: String):
	if condition:
		print("  ✓ PASS: ", message)
		test_passed += 1
	else:
		print("  ✗ FAIL: ", message)
		test_failed += 1

func assert_false(condition: bool, message: String):
	if not condition:
		print("  ✓ PASS: ", message)
		test_passed += 1
	else:
		print("  ✗ FAIL: ", message)
		test_failed += 1
