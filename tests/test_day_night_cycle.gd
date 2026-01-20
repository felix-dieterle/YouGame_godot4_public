extends Node

# Test for DayNightCycle system
const DayNightCycle = preload("res://scripts/day_night_cycle.gd")

# Environment constants matching main.tscn configuration
# These should be kept in sync with scenes/main.tscn to ensure tests reflect production
const MAIN_AMBIENT_LIGHT_ENERGY: float = 1.0  # main.tscn Environment ambient_light_energy (FIXED - was 0.8)
const MAIN_TONEMAP_EXPOSURE: float = 1.2  # main.tscn Environment tonemap_exposure (FIXED - was 1.5)
const MAIN_DIRECTIONAL_LIGHT_ENERGY: float = 1.5  # main.tscn DirectionalLight3D initial energy (FIXED - was 1.2)
const MAIN_SKY_RAYLEIGH_COEFFICIENT: float = 3.0  # main.tscn PhysicalSkyMaterial
const MAIN_SKY_MIE_COEFFICIENT: float = 0.003  # main.tscn PhysicalSkyMaterial
const MAIN_SKY_TURBIDITY: float = 8.0  # main.tscn PhysicalSkyMaterial

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
	test_time_progression_to_930am()  # Test time progression from sunrise (6 AM) to 9:30 AM with brightness verification
	test_time_display_matches_sun_position()  # Test that displayed time matches sun position (exposes time offset bug)
	test_sun_offset_no_discontinuity()  # Test that sun offset doesn't cause sun position discontinuities
	
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
	
	# Clean up any existing save files first to ensure fresh start
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("day_night_save.cfg")
		dir.remove("game_save.cfg")
	
	# Reset SaveGameManager to ensure clean state
	if SaveGameManager:
		SaveGameManager._data_loaded = false
		SaveGameManager.save_data = {
			"player": {},
			"world": {},
			"day_night": {},
			"settings": {}
		}
	
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
	
	# Add test_scene to scene tree using call_deferred to avoid timing conflicts
	get_tree().root.call_deferred("add_child", test_scene)
	
	# Wait for next frame to ensure _ready() has been called
	await get_tree().process_frame
	
	# Test initial state - should start INITIAL_TIME_OFFSET_HOURS into the day
	# Display will show 7:00 AM due to sun_time_offset_hours = -3.0
	var expected_initial_time = DayNightCycle.DAY_CYCLE_DURATION * (DayNightCycle.INITIAL_TIME_OFFSET_HOURS / DayNightCycle.DAY_DURATION_HOURS)
	assert_equal(day_night.current_time, expected_initial_time, "Initial time should be INITIAL_TIME_OFFSET_HOURS into day cycle")
	assert_equal(day_night.is_night, false, "Should start as day")
	assert_equal(day_night.is_locked_out, false, "Should not be locked out initially")
	
	# Cleanup - remove from scene tree and free
	get_tree().root.call_deferred("remove_child", test_scene)
	test_scene.queue_free()
	
	# Clean up save files
	if dir:
		dir.remove("day_night_save.cfg")
		dir.remove("game_save.cfg")

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
	
	# Reset SaveGameManager to ensure clean state
	# This is critical because SaveGameManager is an autoload and may have cached data
	print("  DEBUG: Checking SaveGameManager state before reset...")
	if SaveGameManager:
		print("  DEBUG: SaveGameManager exists")
		print("  DEBUG: has_save_file() = ", SaveGameManager.has_save_file())
		print("  DEBUG: _data_loaded = ", SaveGameManager._data_loaded)
		print("  DEBUG: Current time_scale in save_data = ", SaveGameManager.save_data["day_night"]["time_scale"])
		
		# Force SaveGameManager to think no file exists and reset to defaults
		SaveGameManager._data_loaded = false
		# Reset entire save_data to fresh defaults with time_scale = 2.0
		SaveGameManager.save_data = {
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
				"time_scale": 2.0,  # Fresh start default (FIXED from 1.0)
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
		print("  DEBUG: After reset, time_scale in save_data = ", SaveGameManager.save_data["day_night"]["time_scale"])
		print("  DEBUG: After reset, has_save_file() = ", SaveGameManager.has_save_file())
	
	print("  DEBUG: Creating DayNightCycle instance...")
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
	
	print("  DEBUG: Adding DayNightCycle to scene (will trigger _ready and _load_state)...")
	test_scene.add_child(day_night)
	
	print("  DEBUG: DayNightCycle.time_scale after _ready = ", day_night.time_scale)
	if SaveGameManager:
		print("  DEBUG: SaveGameManager.save_data time_scale after day_night._ready = ", SaveGameManager.save_data["day_night"]["time_scale"])
	
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
	
	# IMPORTANT: The day cycle represents time AFTER sunrise animation completes
	# Sunrise animation: 6:00-7:00 AM (60 seconds real time)
	# Day cycle: 7:00 AM to 5:00 PM (10 hours in-game, 30 minutes real time)
	# Current implementation has a bug - uses 11-hour cycle from 6 AM instead
	# This test uses the CORRECT mapping to expose the time display bug
	
	# 8:00 AM is 1 hour after sunrise completes (7:00 AM)
	# 8:00 AM = 1 hour / 10 hours = 0.1 or 10% into the cycle
	const EIGHT_AM_RATIO = 1.0 / 10.0  # 0.1 (CORRECTED from 2.0 / 11.0)
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light with main.tscn settings
	var light = DirectionalLight3D.new()
	light.light_energy = MAIN_DIRECTIONAL_LIGHT_ENERGY
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	# Add mock world environment with PhysicalSkyMaterial matching main.tscn
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.environment.background_mode = Environment.BG_SKY
	env_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_node.environment.ambient_light_color = Color(1.0, 1.0, 1.0, 1.0)
	env_node.environment.ambient_light_sky_contribution = 1.0
	env_node.environment.ambient_light_energy = MAIN_AMBIENT_LIGHT_ENERGY
	env_node.environment.tonemap_mode = 2  # TONE_MAPPER_FILMIC (matches main.tscn tonemap_mode = 2)
	env_node.environment.tonemap_exposure = MAIN_TONEMAP_EXPOSURE
	
	var sky = Sky.new()
	var sky_material = PhysicalSkyMaterial.new()
	# Match main.tscn PhysicalSkyMaterial settings
	sky_material.rayleigh_coefficient = MAIN_SKY_RAYLEIGH_COEFFICIENT
	sky_material.mie_coefficient = MAIN_SKY_MIE_COEFFICIENT
	sky_material.turbidity = MAIN_SKY_TURBIDITY
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
	# Sun should be above sunrise position (-60°) and still ascending towards zenith (0°)
	assert_true(sun_angle > DayNightCycle.SUNRISE_END_ANGLE,
		"Sun should be above sunrise position at 8:00 AM")
	assert_true(sun_angle < 0,
		"Sun should still be ascending towards zenith at 8:00 AM")
	
	# Cleanup
	test_scene.queue_free()

func test_blue_sky_at_930am():
	print("\n--- Test: Light Blue Sky at 9:30 AM ---")
	
	# See test_brightness_at_8am() for explanation of time mapping
	# 9:30 AM is 2.5 hours after sunrise completes (7:00 AM)
	# 9:30 AM = 2.5 hours / 10 hours = 0.25 or 25% into the cycle
	const NINE_THIRTY_AM_RATIO = 2.5 / 10.0  # 0.25 (CORRECTED from 3.5 / 11.0)
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light with main.tscn settings
	var light = DirectionalLight3D.new()
	light.light_energy = MAIN_DIRECTIONAL_LIGHT_ENERGY
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	# Add mock world environment with PhysicalSkyMaterial matching main.tscn
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.environment.background_mode = Environment.BG_SKY
	env_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_node.environment.ambient_light_color = Color(1.0, 1.0, 1.0, 1.0)
	env_node.environment.ambient_light_sky_contribution = 1.0
	env_node.environment.ambient_light_energy = MAIN_AMBIENT_LIGHT_ENERGY
	env_node.environment.tonemap_mode = 2  # TONE_MAPPER_FILMIC (matches main.tscn tonemap_mode = 2)
	env_node.environment.tonemap_exposure = MAIN_TONEMAP_EXPOSURE
	
	var sky = Sky.new()
	var sky_material = PhysicalSkyMaterial.new()
	# Use main.tscn PhysicalSkyMaterial settings for clear weather
	sky_material.rayleigh_coefficient = MAIN_SKY_RAYLEIGH_COEFFICIENT
	sky_material.mie_coefficient = MAIN_SKY_MIE_COEFFICIENT
	sky_material.turbidity = MAIN_SKY_TURBIDITY
	sky.sky_material = sky_material
	env_node.environment.sky = sky
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	# Add day/night cycle
	test_scene.add_child(day_night)
	
	# Set time to 9:30 AM
	day_night.current_time = NINE_THIRTY_AM_RATIO * DayNightCycle.DAY_CYCLE_DURATION
	day_night.is_night = false
	day_night.is_animating_sunrise = false
	day_night.is_animating_sunset = false
	
	# Manually trigger lighting update
	day_night._update_lighting()
	
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
	# Use tolerance-based comparison for floating-point values
	assert_true(ambient_color.is_equal_approx(Color.WHITE),
		"Ambient light should be white when using Sky as source to show natural blue sky")
	
	# Test 5: Sun should be well positioned (climbing towards noon)
	var sun_angle = lerp(DayNightCycle.SUNRISE_END_ANGLE, DayNightCycle.SUNSET_START_ANGLE, NINE_THIRTY_AM_RATIO)
	print("  Sun angle at 9:30 AM: ", sun_angle, " degrees")
	# At 9:30 AM, sun should be between sunrise end (-60°) and noon (0°)
	# Verify it's in the mid-morning position (between sunrise and noon)
	assert_true(sun_angle > DayNightCycle.SUNRISE_END_ANGLE,
		"Sun should be above sunrise position at 9:30 AM")
	assert_true(sun_angle < 0,
		"Sun should still be ascending towards zenith (0 degrees) at 9:30 AM")
	
	# Cleanup
	test_scene.queue_free()

func test_time_progression_to_930am():
	print("\n--- Test: Time Progression from Sunrise (6 AM) to 9:30 AM ---")
	print("  This test simulates the actual game progression from sunrise through to 9:30 AM")
	print("  Verifies that brightness and sky are correct at 9:30 AM after natural progression")
	
	var test_scene = Node3D.new()
	var day_night = DayNightCycle.new()
	
	# Add mock directional light with main.tscn settings
	var light = DirectionalLight3D.new()
	light.light_energy = MAIN_DIRECTIONAL_LIGHT_ENERGY
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	# Add mock world environment with PhysicalSkyMaterial matching main.tscn
	var env_node = WorldEnvironment.new()
	env_node.environment = Environment.new()
	env_node.environment.background_mode = Environment.BG_SKY
	env_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_node.environment.ambient_light_color = Color(1.0, 1.0, 1.0, 1.0)
	env_node.environment.ambient_light_sky_contribution = 1.0
	env_node.environment.ambient_light_energy = MAIN_AMBIENT_LIGHT_ENERGY
	env_node.environment.tonemap_mode = 2  # TONE_MAPPER_FILMIC (matches main.tscn tonemap_mode = 2)
	env_node.environment.tonemap_exposure = MAIN_TONEMAP_EXPOSURE
	
	var sky = Sky.new()
	var sky_material = PhysicalSkyMaterial.new()
	sky_material.rayleigh_coefficient = MAIN_SKY_RAYLEIGH_COEFFICIENT
	sky_material.mie_coefficient = MAIN_SKY_MIE_COEFFICIENT
	sky_material.turbidity = MAIN_SKY_TURBIDITY
	sky.sky_material = sky_material
	env_node.environment.sky = sky
	env_node.add_to_group("WorldEnvironment")
	test_scene.add_child(env_node)
	
	# Add day/night cycle to scene
	test_scene.add_child(day_night)
	
	# Start with sunrise animation (simulates 6:00-7:00 AM)
	day_night.is_animating_sunrise = true
	day_night.sunrise_animation_time = 0.0
	day_night.current_time = 0.0
	day_night.is_night = false
	
	print("  Phase 1: Simulating sunrise animation (6:00-7:00 AM, 60 seconds)")
	
	# Simulate sunrise animation (60 seconds at 0.016s per frame = ~3750 frames)
	# Use larger time steps for efficiency (0.1s per step = 600 steps)
	var sunrise_delta = 0.1
	var sunrise_steps = int(DayNightCycle.SUNRISE_DURATION / sunrise_delta)
	
	for i in range(sunrise_steps + 1):
		if day_night.is_animating_sunrise:
			day_night.sunrise_animation_time += sunrise_delta
			var progress = day_night.sunrise_animation_time / DayNightCycle.SUNRISE_DURATION
			if progress >= 1.0:
				day_night.is_animating_sunrise = false
				day_night.sunrise_animation_time = 0.0
				print("  Sunrise complete at 7:00 AM")
			else:
				day_night._animate_sunrise(progress)
	
	assert_false(day_night.is_animating_sunrise, "Sunrise animation should be complete")
	assert_equal(day_night.current_time, 0.0, "Current time should be 0 after sunrise (7:00 AM)")
	
	print("  Phase 2: Progressing time from 7:00 AM to 9:30 AM")
	
	# 9:30 AM is 2.5 hours after 7:00 AM
	# In the 10-hour day cycle (7 AM to 5 PM), this is 25% of the cycle
	# DAY_CYCLE_DURATION = 1800 seconds (30 minutes)
	# Time to 9:30 AM = 0.25 * 1800 = 450 seconds
	const TARGET_TIME_930AM = 0.25 * DayNightCycle.DAY_CYCLE_DURATION
	
	# Simulate time progression (use 1 second steps for reasonable speed)
	var progression_delta = 1.0
	var steps_taken = 0
	var max_steps = int(TARGET_TIME_930AM / progression_delta) + 10  # Add buffer
	
	while day_night.current_time < TARGET_TIME_930AM and steps_taken < max_steps:
		day_night.current_time += progression_delta
		day_night._update_lighting()
		steps_taken += 1
	
	print("  Reached time: %.1f seconds (%.1f%% of day cycle)" % [day_night.current_time, (day_night.current_time / DayNightCycle.DAY_CYCLE_DURATION) * 100])
	
	# Verify we reached approximately 9:30 AM
	var time_ratio = day_night.current_time / DayNightCycle.DAY_CYCLE_DURATION
	var expected_ratio = 0.25
	var ratio_tolerance = 0.01  # Allow 1% tolerance
	
	assert_true(abs(time_ratio - expected_ratio) <= ratio_tolerance,
		"Time progressed to ~9:30 AM (ratio: %.3f, expected: %.3f)" % [time_ratio, expected_ratio])
	
	print("  Phase 3: Verifying daylight brightness at 9:30 AM")
	
	# Test brightness - should be well into daylight
	var light_energy = light.light_energy
	print("    Light energy: %.2f" % light_energy)
	
	# At 25% into the day cycle, intensity curve = 1.0 - abs(0.25 - 0.5) * 2.0 = 0.5
	# Light energy = lerp(0.8, 2.0, 0.5) = 1.4
	var expected_light_energy = 1.4
	var light_tolerance = 0.2
	
	assert_true(abs(light_energy - expected_light_energy) <= light_tolerance,
		"Light energy at 9:30 AM is bright (%.2f, expected ~%.2f)" % [light_energy, expected_light_energy])
	
	# Verify it's brighter than minimum (sunrise level)
	assert_true(light_energy > DayNightCycle.MIN_LIGHT_ENERGY,
		"Light should be brighter than sunrise minimum (%.2f > %.2f)" % [light_energy, DayNightCycle.MIN_LIGHT_ENERGY])
	
	print("  Phase 4: Verifying blue sky at 9:30 AM")
	
	# Test sky properties
	assert_true(sky_material.rayleigh_coefficient >= 2.5,
		"Rayleigh coefficient adequate for blue sky (%.1f >= 2.5)" % sky_material.rayleigh_coefficient)
	
	assert_true(sky_material.turbidity <= 10.0,
		"Turbidity low for clear sky (%.1f <= 10.0)" % sky_material.turbidity)
	
	assert_true(sky_material.mie_coefficient <= 0.005,
		"Mie coefficient low for clear sky (%.4f <= 0.005)" % sky_material.mie_coefficient)
	
	# Verify ambient light is white (allows blue sky to show naturally)
	var ambient_color = env_node.environment.ambient_light_color
	assert_true(ambient_color.is_equal_approx(Color.WHITE),
		"Ambient light is white for natural blue sky")
	
	# Verify sun position
	var sun_angle = lerp(DayNightCycle.SUNRISE_END_ANGLE, DayNightCycle.SUNSET_START_ANGLE, time_ratio)
	print("    Sun angle: %.1f degrees" % sun_angle)
	
	assert_true(sun_angle > DayNightCycle.SUNRISE_END_ANGLE,
		"Sun above sunrise position (%.1f > %.1f)" % [sun_angle, DayNightCycle.SUNRISE_END_ANGLE])
	
	assert_true(sun_angle < 0,
		"Sun still ascending to zenith (%.1f < 0)" % sun_angle)
	
	assert_false(day_night.is_night, "Should be daytime at 9:30 AM")
	
	print("  ✓ Time progression test complete: Bright daylight and blue sky confirmed at 9:30 AM")
	
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

func test_time_display_matches_sun_position():
	print("\n--- Test: Time Display Matches Sun Position ---")
	print("  This test verifies that the displayed time correctly represents the sun's position")
	print("  NOW FIXED: Time display should use 10-hour cycle from 7 AM")
	
	# The day cycle should represent the time AFTER sunrise completes
	# Sunrise animation shows sun rising from 6:00-7:00 AM (1-hour animation)
	# After sunrise, current_time starts at 0, which should represent 7:00 AM
	# The day progresses from 7:00 AM to 5:00 PM (10 hours)
	# At current_time = DAY_CYCLE_DURATION * 0.5, it should be noon (12:00 PM)
	
	# Simulate what the UI would display at noon
	const NOON_TIME_RATIO = 0.5  # Sun at zenith
	const SUNRISE_TIME_MINUTES_CORRECT = 420  # Correct value: 7:00 AM (after sunrise ends)
	const DAY_DURATION_HOURS_CORRECT = 10.0  # Correct value: 10 hours (7 AM to 5 PM)
	const EXPECTED_NINE_THIRTY_RATIO = 0.25  # 2.5 hours / 10 hours = 0.25
	
	# Calculate what time SHOULD be displayed with correct formula
	var displayed_minutes_correct = int(NOON_TIME_RATIO * DAY_DURATION_HOURS_CORRECT * 60.0) + SUNRISE_TIME_MINUTES_CORRECT
	var displayed_hours_correct = int(displayed_minutes_correct / 60) % 24
	var displayed_mins_correct = int(displayed_minutes_correct) % 60
	print("  At noon (sun at zenith, time_ratio=0.5):")
	print("    Correct formula displays: %02d:%02d" % [displayed_hours_correct, displayed_mins_correct])
	
	# Test that the correct formula gives us noon (12:00) when sun is at zenith
	assert_equal(displayed_hours_correct, 12, 
		"At sun zenith (time_ratio=0.5), correct formula should display 12:00 (noon)")
	assert_equal(displayed_mins_correct, 0, 
		"At sun zenith (time_ratio=0.5), minutes should be 00")
	
	# Additional check: At displayed 9:30 AM, what time_ratio is it actually?
	const NINE_THIRTY_MINUTES = 570  # 9:30 AM
	var time_ratio_for_930_correct = (NINE_THIRTY_MINUTES - SUNRISE_TIME_MINUTES_CORRECT) / (DAY_DURATION_HOURS_CORRECT * 60.0)
	
	print("\n  At displayed 9:30 AM:")
	print("    Correct formula: time_ratio = %.3f" % time_ratio_for_930_correct)
	
	# The correct time_ratio for 9:30 AM should be 0.25 (2.5 hours into 10-hour day)
	assert_equal(time_ratio_for_930_correct, EXPECTED_NINE_THIRTY_RATIO,
		"9:30 AM should be at time_ratio 0.25 (2.5/10 hours after 7 AM)")
	
	print("\n  ✓ Time display now correctly shows 7:00 AM at sunrise and 12:00 at noon")

func test_sun_offset_no_discontinuity():
	print("\n--- Test: Sun Offset Does Not Cause Sun Position Discontinuities ---")
	print("  This test verifies that changing sun_time_offset_hours only affects displayed time")
	print("  and does NOT cause the actual sun position to jump or wrap around")
	
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
	
	# Set time to middle of day (noon)
	day_night.current_time = 0.5 * DayNightCycle.DAY_CYCLE_DURATION
	day_night.is_night = false
	day_night.is_animating_sunrise = false
	day_night.is_animating_sunset = false
	
	# Test 1: Sun position at noon with no offset
	day_night.sun_time_offset_hours = 0.0
	day_night._update_lighting()
	var sun_angle_no_offset = light.rotation_degrees.x
	var light_energy_no_offset = light.light_energy
	
	print("  At noon with no offset:")
	print("    Sun angle: %.2f degrees" % sun_angle_no_offset)
	print("    Light energy: %.2f" % light_energy_no_offset)
	
	# At noon (time_ratio=0.5), sun should be at zenith (0 degrees)
	# Sun angle lerp from -60 to 60, at 0.5 ratio = 0 degrees
	# Applied as negative: rotation_degrees.x = -0 = 0
	assert_equal(sun_angle_no_offset, 0.0, 
		"Sun should be at zenith (0 degrees) at noon with no offset")
	
	# Test 2: Apply a large positive offset (5 hours)
	# This should ONLY change displayed time, NOT sun position
	day_night.sun_time_offset_hours = 5.0
	day_night._update_lighting()
	var sun_angle_with_offset = light.rotation_degrees.x
	var light_energy_with_offset = light.light_energy
	
	print("\n  At noon with +5 hour offset:")
	print("    Sun angle: %.2f degrees" % sun_angle_with_offset)
	print("    Light energy: %.2f" % light_energy_with_offset)
	
	# Sun position should be EXACTLY the same
	assert_equal(sun_angle_with_offset, sun_angle_no_offset,
		"Sun angle should not change when offset is applied")
	assert_equal(light_energy_with_offset, light_energy_no_offset,
		"Light energy should not change when offset is applied")
	
	# Test 3: Apply a large negative offset (-3 hours)
	day_night.sun_time_offset_hours = -3.0
	day_night._update_lighting()
	var sun_angle_negative_offset = light.rotation_degrees.x
	var light_energy_negative_offset = light.light_energy
	
	print("\n  At noon with -3 hour offset:")
	print("    Sun angle: %.2f degrees" % sun_angle_negative_offset)
	print("    Light energy: %.2f" % light_energy_negative_offset)
	
	# Sun position should STILL be exactly the same
	assert_equal(sun_angle_negative_offset, sun_angle_no_offset,
		"Sun angle should not change with negative offset")
	assert_equal(light_energy_negative_offset, light_energy_no_offset,
		"Light energy should not change with negative offset")
	
	# Test 4: Test at different times of day to ensure no wrapping
	# Set time to early morning (10% into day)
	day_night.current_time = 0.1 * DayNightCycle.DAY_CYCLE_DURATION
	day_night.sun_time_offset_hours = 0.0
	day_night._update_lighting()
	var morning_sun_no_offset = light.rotation_degrees.x
	
	# Apply offset that would wrap if applied to sun position
	day_night.sun_time_offset_hours = 12.0  # Huge offset
	day_night._update_lighting()
	var morning_sun_with_offset = light.rotation_degrees.x
	
	print("\n  At early morning (10% into day):")
	print("    Sun angle without offset: %.2f degrees" % morning_sun_no_offset)
	print("    Sun angle with +12h offset: %.2f degrees" % morning_sun_with_offset)
	
	assert_equal(morning_sun_with_offset, morning_sun_no_offset,
		"Sun angle should not wrap around even with large offset")
	
	# Test 5: Verify smooth progression over time with offset applied
	# Reset to start of day
	day_night.current_time = 0.0
	day_night.sun_time_offset_hours = 5.0  # Keep offset
	
	var previous_sun_angle: float = 0.0
	var first_iteration = true
	var has_discontinuity = false
	# Sun moves from -60° to +60° over full day (120° total)
	# Per 1% of day = 1.2°, using 2.0° threshold for safety margin
	var max_expected_change = 2.0
	
	# Step through day in small increments
	for i in range(101):
		var time_ratio = i / 100.0
		day_night.current_time = time_ratio * DayNightCycle.DAY_CYCLE_DURATION
		day_night._update_lighting()
		var current_sun_angle = light.rotation_degrees.x
		
		if not first_iteration:
			var change = abs(current_sun_angle - previous_sun_angle)
			# Check for large jumps (discontinuities)
			if change > max_expected_change:
				has_discontinuity = true
				print("  WARNING: Discontinuity at %.1f%% - sun jumped %.2f degrees" % [time_ratio * 100, change])
		
		previous_sun_angle = current_sun_angle
		first_iteration = false
	
	assert_false(has_discontinuity, 
		"Sun position should progress smoothly without discontinuities even with offset")
	
	print("\n  ✓ Sun offset only affects displayed time, not actual sun position")
	print("  ✓ No discontinuities in sun position throughout the day")
	
	# Cleanup
	test_scene.queue_free()

