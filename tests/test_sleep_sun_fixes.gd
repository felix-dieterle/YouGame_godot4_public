extends GutTest

# Test for sleep timer and sun brightness fixes
# Tests the fixes for:
# 1. Night overlay stuck on screen when lockout expires during restart
# 2. Improved sun brightness curve for more realistic lighting

func test_night_overlay_hidden_when_lockout_expires_on_load():
	print("\n--- Test: Night overlay hidden when lockout expires on load ---")
	
	# GIVEN: A saved game with an expired lockout
	var current_unix_time = Time.get_unix_time_from_system()
	var expired_lockout_time = current_unix_time - 100.0  # Lockout expired 100 seconds ago
	
	# Save the expired lockout state
	SaveGameManager._data_loaded = true
	SaveGameManager._save_data = {
		"day_night": {
			"is_locked_out": true,
			"lockout_end_time": expired_lockout_time,
			"current_time": 0.0,
			"time_scale": 2.0,
			"day_count": 1,
			"night_start_time": expired_lockout_time - DayNightCycle.SLEEP_LOCKOUT_DURATION
		}
	}
	
	# Create a test scene
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	# Create mock UI manager
	var ui_manager = Node.new()
	ui_manager.name = "UIManager"
	var night_overlay_hidden = false
	
	# Mock show_night_overlay
	ui_manager.set_script(GDScript.new())
	ui_manager.get_script().source_code = """
	extends Node
	var show_night_overlay_called = false
	var hide_night_overlay_called = false
	
	func show_night_overlay(lockout_end_time: float):
		show_night_overlay_called = true
	
	func hide_night_overlay():
		hide_night_overlay_called = true
	
	func has_method(method_name):
		return method_name in ["show_night_overlay", "hide_night_overlay", "show_message"]
	
	func show_message(msg: String, duration: float = 3.0):
		pass
	"""
	ui_manager.get_script().reload()
	test_scene.add_child(ui_manager)
	
	# Create day/night cycle
	var day_night = DayNightCycle.new()
	day_night.debug_skip_lockout = false  # Don't skip lockout
	test_scene.add_child(day_night)
	
	# Wait for _ready to be called
	await wait_frames(2)
	
	# THEN: Night overlay should have been hidden (not shown)
	# Because lockout expired, _hide_night_screen() should be called
	assert_true(ui_manager.hide_night_overlay_called, 
		"hide_night_overlay should be called when lockout has expired")
	
	# Cleanup
	test_scene.queue_free()
	SaveGameManager._save_data = {}

func test_quadratic_brightness_curve_brighter_early_morning():
	print("\n--- Test: Quadratic brightness curve is brighter in early morning ---")
	
	# GIVEN: A day/night cycle at early morning (30° sun position)
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	var day_night = DayNightCycle.new()
	test_scene.add_child(day_night)
	
	# Wait for initialization
	await wait_frames(2)
	
	# Set time to 30° (early morning)
	# 30° / 180° = 0.167 or 16.7% into day
	day_night.current_time = 0.167 * DayNightCycle.DAY_CYCLE_DURATION
	day_night.is_night = false
	day_night.is_animating_sunrise = false
	day_night.is_animating_sunset = false
	
	# Update lighting
	day_night._update_lighting()
	
	# THEN: Light energy should be significantly higher than with linear curve
	# At 30°: noon_distance = 0.667
	# Quadratic curve: 1.0 - (0.667^2) = 0.556
	# Expected energy: 1.2 + (3.0 - 1.2) * 0.556 = 2.20
	var expected_energy = 1.2 + (3.0 - 1.2) * (1.0 - 0.667 * 0.667)
	assert_almost_eq(light.light_energy, expected_energy, 0.01,
		"Light energy at 30° should match quadratic curve calculation (%.2f)" % expected_energy)
	
	# Should be significantly brighter than linear curve would give (1.80)
	var linear_energy = 1.2 + (3.0 - 1.2) * (1.0 - 0.667)
	assert_gt(light.light_energy, linear_energy + 0.3,
		"Quadratic curve should be at least 0.3 brighter than linear at 30°")
	
	# Cleanup
	test_scene.queue_free()

func test_quadratic_brightness_curve_plateau_at_noon():
	print("\n--- Test: Quadratic brightness curve creates plateau at noon ---")
	
	# GIVEN: Day/night cycle at different times around noon
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	var light = DirectionalLight3D.new()
	light.add_to_group("DirectionalLight3D")
	test_scene.add_child(light)
	
	var day_night = DayNightCycle.new()
	test_scene.add_child(day_night)
	
	await wait_frames(2)
	
	day_night.is_night = false
	day_night.is_animating_sunrise = false
	day_night.is_animating_sunset = false
	
	# Test brightness at 70°, 80°, 90°, 100°, 110°
	var brightness_values = []
	for angle in [70, 80, 90, 100, 110]:
		var time_ratio = angle / 180.0
		day_night.current_time = time_ratio * DayNightCycle.DAY_CYCLE_DURATION
		day_night._update_lighting()
		brightness_values.append(light.light_energy)
	
	# THEN: All values should be close to maximum (>2.9)
	for i in range(brightness_values.size()):
		var angle = [70, 80, 90, 100, 110][i]
		var brightness = brightness_values[i]
		assert_gt(brightness, 2.9,
			"Brightness at %d° should be > 2.9 (was %.2f)" % [angle, brightness])
	
	# Maximum should be at 90°
	assert_almost_eq(brightness_values[2], 3.0, 0.01,
		"Maximum brightness should be at 90° (noon)")
	
	# Cleanup
	test_scene.queue_free()
