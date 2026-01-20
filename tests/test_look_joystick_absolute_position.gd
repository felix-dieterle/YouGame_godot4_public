extends Node

# Test suite for verifying the look joystick absolute position control feature
# 
# This test verifies that the look joystick works with absolute positioning:
# - The joystick circle represents exactly 80 degrees in all directions
# - Pushing the stick directly sets the camera angle (not velocity)
# - The stick stays exactly where you push it

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Look Joystick Absolute Position Tests ===")
	
	# Run tests
	await test_joystick_position_maps_to_target_angles()
	await test_joystick_edge_maps_to_max_angle()
	await test_player_uses_absolute_positioning()
	await test_stick_stays_where_pushed()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== Look Joystick Absolute Position Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_joystick_position_maps_to_target_angles():
	print("\n--- Test: Joystick Position Maps to Target Angles ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if not mobile_controls_script:
		assert_fail("Could not load mobile controls script")
		return
	
	var mobile_controls = mobile_controls_script.new()
	mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls.anchor_right = 1.0
	mobile_controls.anchor_bottom = 1.0
	mobile_controls.z_index = 10
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Create a mock player
	var player_script = load("res://scripts/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	mobile_controls.get_parent().add_child(player)
	await get_tree().process_frame
	
	mobile_controls.player = player
	
	# Simulate touch on joystick at center (should give 0,0 angles)
	var joystick_center = mobile_controls.look_joystick_base.position
	var touch_event = InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.position = joystick_center
	touch_event.index = 0
	
	mobile_controls._input(touch_event)
	await get_tree().process_frame
	
	# Check that target angles are zero
	var target_angles = mobile_controls.get_look_target_angles()
	if abs(target_angles.x) < 0.01 and abs(target_angles.y) < 0.01:
		assert_pass("Center position maps to zero target angles")
	else:
		assert_fail("Center position should map to (0,0) but got (%.3f, %.3f)" % [target_angles.x, target_angles.y])
	
	# Clean up
	player.queue_free()
	mobile_controls.queue_free()

func test_joystick_edge_maps_to_max_angle():
	print("\n--- Test: Joystick Edge Maps to Max Angle ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if not mobile_controls_script:
		assert_fail("Could not load mobile controls script")
		return
	
	var mobile_controls = mobile_controls_script.new()
	mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls.anchor_right = 1.0
	mobile_controls.anchor_bottom = 1.0
	mobile_controls.z_index = 10
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Create a mock player
	var player_script = load("res://scripts/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	mobile_controls.get_parent().add_child(player)
	await get_tree().process_frame
	
	mobile_controls.player = player
	
	# Simulate touch at right edge of joystick (should give max yaw)
	var joystick_center = mobile_controls.look_joystick_base.position
	var radius = 80.0  # JOYSTICK_RADIUS
	var touch_event = InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.position = joystick_center + Vector2(radius, 0)  # Right edge
	touch_event.index = 0
	
	mobile_controls._input(touch_event)
	await get_tree().process_frame
	
	# Check that target yaw is at max (80 degrees)
	var target_angles = mobile_controls.get_look_target_angles()
	var expected_yaw = deg_to_rad(80.0)
	if abs(target_angles.x - expected_yaw) < 0.01:
		assert_pass("Right edge maps to +80° yaw (%.1f°)" % rad_to_deg(target_angles.x))
	else:
		assert_fail("Right edge should map to +80° yaw but got %.1f°" % rad_to_deg(target_angles.x))
	
	# Clean up
	player.queue_free()
	mobile_controls.queue_free()

func test_player_uses_absolute_positioning():
	print("\n--- Test: Player Uses Absolute Positioning ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if not mobile_controls_script:
		assert_fail("Could not load mobile controls script")
		return
	
	var mobile_controls = mobile_controls_script.new()
	mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls.anchor_right = 1.0
	mobile_controls.anchor_bottom = 1.0
	mobile_controls.z_index = 10
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Create player
	var player_script = load("res://scripts/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	add_child(player)
	await get_tree().process_frame
	
	# Set mobile controls reference in player
	player.mobile_controls = mobile_controls
	mobile_controls.player = player
	
	# Simulate touch at specific position (40 degrees right, 30 degrees up)
	var joystick_center = mobile_controls.look_joystick_base.position
	var radius = 80.0  # JOYSTICK_RADIUS
	# 40 degrees = 0.5 * 80 degrees, 30 degrees = 0.375 * 80 degrees
	var offset = Vector2(radius * 0.5, radius * 0.375)
	
	var touch_event = InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.position = joystick_center + offset
	touch_event.index = 0
	
	mobile_controls._input(touch_event)
	await get_tree().process_frame
	
	# Process physics to apply the rotation
	player._physics_process(0.016)
	await get_tree().process_frame
	
	# Check that player's camera rotation matches the target
	var expected_yaw = deg_to_rad(40.0)
	var expected_pitch = deg_to_rad(30.0)
	
	if abs(player.camera_rotation_y - expected_yaw) < 0.1:
		assert_pass("Player camera yaw set to %.1f° (expected %.1f°)" % [rad_to_deg(player.camera_rotation_y), rad_to_deg(expected_yaw)])
	else:
		assert_fail("Player camera yaw should be %.1f° but is %.1f°" % [rad_to_deg(expected_yaw), rad_to_deg(player.camera_rotation_y)])
	
	if abs(player.camera_rotation_x - expected_pitch) < 0.1:
		assert_pass("Player camera pitch set to %.1f° (expected %.1f°)" % [rad_to_deg(player.camera_rotation_x), rad_to_deg(expected_pitch)])
	else:
		assert_fail("Player camera pitch should be %.1f° but is %.1f°" % [rad_to_deg(expected_pitch), rad_to_deg(player.camera_rotation_x)])
	
	# Clean up
	player.queue_free()
	mobile_controls.queue_free()

func test_stick_stays_where_pushed():
	print("\n--- Test: Stick Stays Where Pushed ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if not mobile_controls_script:
		assert_fail("Could not load mobile controls script")
		return
	
	var mobile_controls = mobile_controls_script.new()
	mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls.anchor_right = 1.0
	mobile_controls.anchor_bottom = 1.0
	mobile_controls.z_index = 10
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Create player
	var player_script = load("res://scripts/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	add_child(player)
	await get_tree().process_frame
	
	mobile_controls.player = player
	
	# Simulate touch at a specific position
	var joystick_center = mobile_controls.look_joystick_base.position
	var radius = 80.0
	var offset = Vector2(radius * 0.6, radius * 0.4)
	
	var touch_event = InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.position = joystick_center + offset
	touch_event.index = 0
	
	mobile_controls._input(touch_event)
	await get_tree().process_frame
	
	# Store stick position
	var stick_position = mobile_controls.look_joystick_stick.position
	
	# Process several frames while touch is active
	for i in range(5):
		await get_tree().process_frame
	
	# Verify stick position hasn't changed
	var stick_position_after = mobile_controls.look_joystick_stick.position
	if stick_position.distance_to(stick_position_after) < 0.1:
		assert_pass("Stick stays at pushed position during active touch")
	else:
		assert_fail("Stick should stay at pushed position but moved from (%.1f, %.1f) to (%.1f, %.1f)" % [
			stick_position.x, stick_position.y,
			stick_position_after.x, stick_position_after.y
		])
	
	# Clean up
	player.queue_free()
	mobile_controls.queue_free()

# Helper functions for tracking test results
func assert_pass(message: String):
	print("  ✓ PASS: ", message)
	test_passed += 1

func assert_fail(message: String):
	print("  ✗ FAIL: ", message)
	test_failed += 1
