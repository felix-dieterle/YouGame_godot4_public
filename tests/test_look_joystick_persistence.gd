extends Node

# Test suite for verifying the look joystick stick position persistence feature
# 
# This test verifies that the look joystick stick position reflects the current
# camera rotation, rather than resetting to center when the user releases the touch.

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Look Joystick Persistence Tests ===")
	
	# Run tests
	await test_joystick_position_reflects_camera_rotation()
	await test_joystick_position_updates_continuously()
	await test_joystick_position_not_updated_during_touch()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== Look Joystick Persistence Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_joystick_position_reflects_camera_rotation():
	print("\n--- Test: Joystick Position Reflects Camera Rotation ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/ui/mobile_controls.gd")
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
	
	# Create a mock player with camera rotation
	var player_script = load("res://scripts/systems/character/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	mobile_controls.get_parent().add_child(player)
	await get_tree().process_frame
	
	# Set player reference in mobile controls
	mobile_controls.player = player
	
	# Set camera rotation to a known value
	player.camera_rotation_y = deg_to_rad(40.0)  # 40 degrees right (yaw)
	player.camera_rotation_x = deg_to_rad(30.0)  # 30 degrees up (pitch)
	
	# Process a frame to update joystick position
	await get_tree().process_frame
	
	# Check that the joystick stick position is not at center (0, 0)
	var stick_pos = mobile_controls.look_joystick_stick.position
	if stick_pos.length() > 1.0:  # Should be offset from center
		assert_pass("Look joystick stick is offset from center: (%.1f, %.1f)" % [stick_pos.x, stick_pos.y])
		
		# Verify the stick position is in the expected direction
		# 40 degrees right = positive X, 30 degrees up = positive Y
		if stick_pos.x > 0:
			assert_pass("Stick X position is positive for rightward camera rotation")
		else:
			assert_fail("Stick X position should be positive for rightward camera rotation but is %.1f" % stick_pos.x)
		
		if stick_pos.y > 0:
			assert_pass("Stick Y position is positive for upward camera rotation")
		else:
			assert_fail("Stick Y position should be positive for upward camera rotation but is %.1f" % stick_pos.y)
	else:
		assert_fail("Look joystick stick should be offset from center but is at (%.1f, %.1f)" % [stick_pos.x, stick_pos.y])
	
	# Clean up
	player.queue_free()
	mobile_controls.queue_free()

func test_joystick_position_updates_continuously():
	print("\n--- Test: Joystick Position Updates Continuously ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/ui/mobile_controls.gd")
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
	var player_script = load("res://scripts/systems/character/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	mobile_controls.get_parent().add_child(player)
	await get_tree().process_frame
	
	mobile_controls.player = player
	
	# Set initial camera rotation
	player.camera_rotation_y = deg_to_rad(20.0)
	player.camera_rotation_x = deg_to_rad(10.0)
	await get_tree().process_frame
	
	var initial_pos = mobile_controls.look_joystick_stick.position
	
	# Change camera rotation
	player.camera_rotation_y = deg_to_rad(40.0)
	player.camera_rotation_x = deg_to_rad(20.0)
	await get_tree().process_frame
	
	var updated_pos = mobile_controls.look_joystick_stick.position
	
	# Verify position changed
	if updated_pos.distance_to(initial_pos) > 1.0:
		assert_pass("Joystick position updated after camera rotation changed")
	else:
		assert_fail("Joystick position should update when camera rotation changes")
	
	# Clean up
	player.queue_free()
	mobile_controls.queue_free()

func test_joystick_position_not_updated_during_touch():
	print("\n--- Test: Joystick Position Not Updated During Touch ---")
	
	# Create mobile controls
	var mobile_controls_script = load("res://scripts/ui/mobile_controls.gd")
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
	var player_script = load("res://scripts/systems/character/player.gd")
	if not player_script:
		assert_fail("Could not load player script")
		mobile_controls.queue_free()
		return
	
	var player = player_script.new()
	mobile_controls.get_parent().add_child(player)
	await get_tree().process_frame
	
	mobile_controls.player = player
	
	# Simulate active touch on look joystick
	mobile_controls.look_joystick_active = true
	mobile_controls.look_joystick_stick.position = Vector2(30.0, 20.0)
	
	var touch_pos = mobile_controls.look_joystick_stick.position
	
	# Change camera rotation while touch is active
	player.camera_rotation_y = deg_to_rad(60.0)
	player.camera_rotation_x = deg_to_rad(50.0)
	await get_tree().process_frame
	
	# Verify position did NOT change (because touch is active)
	if mobile_controls.look_joystick_stick.position.distance_to(touch_pos) < 0.1:
		assert_pass("Joystick position not updated during active touch")
	else:
		assert_fail("Joystick position should not update during active touch")
	
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
