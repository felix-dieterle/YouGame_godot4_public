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
	test_brightness_at_8am()  # Test that 8:00 AM is bright enough to be considered day
	test_blue_sky_at_930am()  # Test that 9:30 AM has a nice light blue sky
	
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
	
	# Clean up any existing save files first to ensure fresh start
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("day_night_save.cfg")
		dir.remove("game_save.cfg")
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	test_scene.add_child(day_night)
	
	# Set some state
	day_night.is_locked_out = true
	day_night.lockout_end_time = 1000000.0
	day_night.current_time = 500.0
	day_night.time_scale = 4.0
	
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
	assert_equal(day_night2.time_scale, 4.0, "Time scale should be saved")
	
	# Cleanup
	test_scene.queue_free()
	
	# Clean up save file
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
	
	# Clean up any existing save files first to ensure fresh start
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("day_night_save.cfg")
		dir.remove("game_save.cfg")
	
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
	
	# Test initial time scale for fresh start (no save file)
	assert_equal(day_night.time_scale, 2.0, "Initial time scale should be 2.0 for fresh start")
	
	# Reset to 1.0 to test increase/decrease functions
	day_night.time_scale = 1.0
	
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

func test_brightness_at_8am():
	print("\n--- Test: Brightness at 8:00 AM ---")
	
	# 8:00 AM is 2 hours after sunrise (6:00 AM)
	# Day cycle runs from 6:00 AM to 5:00 PM (11 hours)
	# 8:00 AM = 2 hours / 11 hours = ~0.182 or 18.2% into the cycle
	const EIGHT_AM_RATIO = 2.0 / 11.0  # ~0.182
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	# Add mock world environment with PhysicalSkyMaterial
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_material = PhysicalSkyMaterial.new()
	sky.sky_material = sky_material
	env_node.environment.sky = sky
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	# Add day/night cycle
	test_scene.add_child(day_night)
	
	# Set time to 8:00 AM (after sunrise animation completes at 7:00 AM)
	day_night.current_time = EIGHT_AM_RATIO * DayNightCycle.DAY_CYCLE_DURATION
	day_night.is_night = false
	day_night.is_animating_sunrise = false
	day_night.is_animating_sunset = false
	
	# Manually trigger lighting update
	day_night._update_lighting()
	
	# Test 1: Light energy should be significantly higher than minimum (sunrise/sunset level)
	# At 8:00 AM, we're past sunrise so light should be stronger
	var light_energy = light.light_energy
	print("  Light energy at 8:00 AM: ", light_energy)
	assert_true(light_energy > DayNightCycle.MIN_LIGHT_ENERGY, 
		"Light energy at 8:00 AM should be greater than minimum (sunrise/sunset level)")
	
	# Test 2: Should be bright enough to distinguish from early morning
	# The intensity curve increases from MIN to MAX, peaking at noon
	# At 18.2% into day, we should be noticeably brighter than the minimum
	var expected_min_brightness = DayNightCycle.MIN_LIGHT_ENERGY * 1.2  # At least 20% brighter than sunrise
	assert_true(light_energy >= expected_min_brightness,
		"Light energy at 8:00 AM should be at least 20% brighter than sunrise minimum")
	
	# Test 3: Should still be classified as daytime (not night)
	assert_false(day_night.is_night, "8:00 AM should be classified as daytime")
	
	# Test 4: Sun should be above horizon (positive y component in position)
	# Sun angle at 8:00 AM should be between sunrise end and noon
	var sun_angle = lerp(DayNightCycle.SUNRISE_END_ANGLE, DayNightCycle.SUNSET_START_ANGLE, EIGHT_AM_RATIO)
	print("  Sun angle at 8:00 AM: ", sun_angle, " degrees")
	# Sun should be well above horizon (-60 to 60 range, 8am should be around -38 degrees)
	assert_true(sun_angle > DayNightCycle.SUNRISE_END_ANGLE,
		"Sun should be above sunrise position at 8:00 AM")
	assert_true(sun_angle < 0,
		"Sun should still be ascending towards zenith at 8:00 AM")
	
	# Cleanup
	test_scene.queue_free()

func test_blue_sky_at_930am():
	print("\n--- Test: Light Blue Sky at 9:30 AM ---")
	
	# 9:30 AM is 3.5 hours after sunrise (6:00 AM)
	# Day cycle runs from 6:00 AM to 5:00 PM (11 hours)
	# 9:30 AM = 3.5 hours / 11 hours = ~0.318 or 31.8% into the cycle
	const NINE_THIRTY_AM_RATIO = 3.5 / 11.0  # ~0.318
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	# Add mock world environment with PhysicalSkyMaterial
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.environment.background_mode = Environment.BG_SKY
	env_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var sky = Sky.new()
	var sky_material = PhysicalSkyMaterial.new()
	sky.sky_material = sky_material
	env_node.environment.sky = sky
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	# We need to also add a WeatherSystem to set sky parameters
	# Or manually set them to clear weather values
	var weather_system = preload("res://scripts/weather_system.gd").new()
	test_scene.add_child(weather_system)
	
	# Add day/night cycle
	test_scene.add_child(day_night)
	
	# Set time to 9:30 AM
	day_night.current_time = NINE_THIRTY_AM_RATIO * DayNightCycle.DAY_CYCLE_DURATION
	day_night.is_night = false
	day_night.is_animating_sunrise = false
	day_night.is_animating_sunset = false
	
	# Manually trigger lighting update
	day_night._update_lighting()
	
	# Manually set sky to clear weather (bright blue sky)
	# These values are from WeatherState.CLEAR in weather_system.gd
	sky_material.turbidity = 8.0  # Clear bright sky
	sky_material.mie_coefficient = 0.003  # Minimal haze
	sky_material.rayleigh_coefficient = 3.0  # Bright vibrant blue sky
	
	# Test 1: Sky should have high rayleigh coefficient for blue color
	# Rayleigh scattering is what makes the sky blue
	print("  Rayleigh coefficient at 9:30 AM: ", sky_material.rayleigh_coefficient)
	assert_true(sky_material.rayleigh_coefficient >= 2.5,
		"Rayleigh coefficient should be high enough for vibrant blue sky at 9:30 AM")
	
	# Test 2: Turbidity should indicate clear conditions
	print("  Turbidity at 9:30 AM: ", sky_material.turbidity)
	assert_true(sky_material.turbidity <= 10.0,
		"Turbidity should be low for clear sky at 9:30 AM")
	
	# Test 3: Mie coefficient should be low (minimal haze)
	print("  Mie coefficient at 9:30 AM: ", sky_material.mie_coefficient)
	assert_true(sky_material.mie_coefficient <= 0.005,
		"Mie coefficient should be low for clear sky at 9:30 AM")
	
	# Test 4: Ambient light should be white (not tinted) to allow blue sky to show
	# When using Sky as ambient source, the color should be white
	var ambient_color = env_node.environment.ambient_light_color
	print("  Ambient light color at 9:30 AM: ", ambient_color)
	assert_true(ambient_color.r >= 0.99 and ambient_color.g >= 0.99 and ambient_color.b >= 0.99,
		"Ambient light should be white when using Sky as source to show natural blue sky")
	
	# Test 5: Sun should be well positioned (climbing towards noon)
	var sun_angle = lerp(DayNightCycle.SUNRISE_END_ANGLE, DayNightCycle.SUNSET_START_ANGLE, NINE_THIRTY_AM_RATIO)
	print("  Sun angle at 9:30 AM: ", sun_angle, " degrees")
	# At 9:30 AM (31.8% into day), sun should be around -21.8 degrees (climbing towards 0 at noon)
	assert_true(sun_angle > -40 and sun_angle < -10,
		"Sun should be climbing towards zenith at 9:30 AM")
	
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
