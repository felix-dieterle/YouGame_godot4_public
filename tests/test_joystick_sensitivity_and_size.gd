extends Node

# Test suite to verify joystick sensitivity and size adjustments
# Tests that:
# 1. Movement joystick has 0.5x horizontal sensitivity
# 2. Look joystick is 1.5x larger than movement joystick

var mobile_controls: Control
var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Joystick Sensitivity and Size Tests ===")
	
	# Run tests
	test_joystick_constants()
	await test_movement_joystick_sensitivity()
	test_look_joystick_size()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_joystick_constants():
	print("\n--- Test: Joystick Constants ---")
	
	# Load the mobile controls script
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if not mobile_controls_script:
		assert_fail("Could not load MobileControls script")
		return
	
	# Create an instance
	mobile_controls = mobile_controls_script.new()
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Check JOYSTICK_RADIUS constant (should be 80.0)
	var movement_radius = mobile_controls.JOYSTICK_RADIUS
	if movement_radius == 80.0:
		assert_pass("Movement joystick radius is 80.0")
	else:
		assert_fail("Movement joystick radius should be 80.0, got %f" % movement_radius)
	
	# Check LOOK_JOYSTICK_RADIUS constant (should be 120.0, which is 1.5x of 80.0)
	var look_radius = mobile_controls.LOOK_JOYSTICK_RADIUS
	if look_radius == 120.0:
		assert_pass("Look joystick radius is 120.0 (1.5x movement)")
	else:
		assert_fail("Look joystick radius should be 120.0, got %f" % look_radius)
	
	# Verify the ratio
	var ratio = look_radius / movement_radius
	if abs(ratio - 1.5) < 0.01:
		assert_pass("Look joystick is 1.5x larger than movement joystick")
	else:
		assert_fail("Look joystick should be 1.5x larger, ratio is %f" % ratio)
	
	# Check MOVEMENT_HORIZONTAL_SENSITIVITY constant (should be 0.5)
	var horizontal_sensitivity = mobile_controls.MOVEMENT_HORIZONTAL_SENSITIVITY
	if horizontal_sensitivity == 0.5:
		assert_pass("Movement horizontal sensitivity is 0.5 (half as sensitive)")
	else:
		assert_fail("Movement horizontal sensitivity should be 0.5, got %f" % horizontal_sensitivity)

func test_movement_joystick_sensitivity():
	print("\n--- Test: Movement Joystick Horizontal Sensitivity ---")
	
	if not mobile_controls:
		assert_fail("MobileControls not initialized")
		return
	
	# Simulate a touch at a position that would normally produce normalized vector (0.8, 0.6)
	# With horizontal sensitivity of 0.5, we expect output (0.4, 0.6)
	
	# Get the joystick center position
	var joystick_center = mobile_controls.joystick_base.position
	
	# Create a test offset (80% right, 60% up from center)
	var test_offset = Vector2(0.8, 0.6) * mobile_controls.JOYSTICK_RADIUS
	var touch_pos = joystick_center + test_offset
	
	# Simulate a touch event
	var event = InputEventScreenTouch.new()
	event.pressed = true
	event.index = 0
	event.position = touch_pos
	mobile_controls._input(event)
	
	await get_tree().process_frame
	
	# Get the input vector
	var input_vector = mobile_controls.get_input_vector()
	
	# Expected: X should be 0.8 * 0.5 = 0.4, Y should be 0.6
	var expected_x = 0.4
	var expected_y = 0.6
	var tolerance = 0.05
	
	if abs(input_vector.x - expected_x) < tolerance:
		assert_pass("Movement joystick X sensitivity is correct (%.2f ≈ %.2f)" % [input_vector.x, expected_x])
	else:
		assert_fail("Movement joystick X should be %.2f but got %.2f" % [expected_x, input_vector.x])
	
	if abs(input_vector.y - expected_y) < tolerance:
		assert_pass("Movement joystick Y is unaffected (%.2f ≈ %.2f)" % [input_vector.y, expected_y])
	else:
		assert_fail("Movement joystick Y should be %.2f but got %.2f" % [expected_y, input_vector.y])
	
	# Release the touch
	event.pressed = false
	mobile_controls._input(event)

func test_look_joystick_size():
	print("\n--- Test: Look Joystick Size ---")
	
	if not mobile_controls:
		assert_fail("MobileControls not initialized")
		return
	
	var look_base = mobile_controls.look_joystick_base
	if not look_base:
		assert_fail("look_joystick_base not found")
		return
	
	# Check that the look joystick base has the correct size
	var expected_size = Vector2(120.0 * 2, 120.0 * 2)  # LOOK_JOYSTICK_RADIUS * 2
	
	if look_base.size.is_equal_approx(expected_size):
		assert_pass("Look joystick base size is correct: %.0fx%.0f" % [look_base.size.x, look_base.size.y])
	else:
		assert_fail("Look joystick base size should be %.0fx%.0f but is %.0fx%.0f" % [expected_size.x, expected_size.y, look_base.size.x, look_base.size.y])
	
	# Check the stick size
	var look_stick = mobile_controls.look_joystick_stick
	if not look_stick:
		assert_fail("look_joystick_stick not found")
		return
	
	var expected_stick_size = Vector2(45.0 * 2, 45.0 * 2)  # LOOK_STICK_RADIUS * 2
	
	if look_stick.size.is_equal_approx(expected_stick_size):
		assert_pass("Look joystick stick size is correct: %.0fx%.0f" % [look_stick.size.x, look_stick.size.y])
	else:
		assert_fail("Look joystick stick size should be %.0fx%.0f but is %.0fx%.0f" % [expected_stick_size.x, expected_stick_size.y, look_stick.size.x, look_stick.size.y])

func assert_pass(message: String):
	test_passed += 1
	print("✓ PASS: ", message)

func assert_fail(message: String):
	test_failed += 1
	print("✗ FAIL: ", message)
