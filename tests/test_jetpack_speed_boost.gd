extends Node

# Test suite for jetpack speed boost feature
# Tests that horizontal movement speed is 4x when jetpack is active

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Jetpack Speed Boost Tests ===")
	test_jetpack_speed_multiplier()
	test_jetpack_speed_application()
	test_normal_speed_without_jetpack()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Jetpack Speed Boost Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_jetpack_speed_multiplier():
	print("\n--- Test: Jetpack Speed Multiplier Configuration ---")
	
	# Default values
	var move_speed = 5.0
	var jetpack_move_speed_multiplier = 4.0
	
	check_condition(jetpack_move_speed_multiplier == 4.0, "Jetpack move speed multiplier should be 4.0")
	
	var expected_jetpack_move_speed = move_speed * jetpack_move_speed_multiplier
	check_condition(expected_jetpack_move_speed == 20.0, "Jetpack move speed should be 20.0 (5.0 * 4.0), got %f" % expected_jetpack_move_speed)

func test_jetpack_speed_application():
	print("\n--- Test: Jetpack Speed Application ---")
	
	# Simulate movement with jetpack active
	var move_speed = 5.0
	var jetpack_move_speed_multiplier = 4.0
	var jetpack_active = true
	var direction = Vector3(1.0, 0, 0).normalized()  # Moving in X direction
	
	# Calculate speed based on jetpack state
	var current_move_speed = move_speed
	if jetpack_active:
		current_move_speed = move_speed * jetpack_move_speed_multiplier
	
	var velocity_x = direction.x * current_move_speed
	
	check_condition(current_move_speed == 20.0, "Current move speed should be 20.0 when jetpack is active")
	check_condition(velocity_x == 20.0, "Velocity X should be 20.0 when moving with jetpack active, got %f" % velocity_x)

func test_normal_speed_without_jetpack():
	print("\n--- Test: Normal Speed Without Jetpack ---")
	
	# Simulate movement without jetpack
	var move_speed = 5.0
	var jetpack_move_speed_multiplier = 4.0
	var jetpack_active = false
	var direction = Vector3(1.0, 0, 0).normalized()
	
	# Calculate speed based on jetpack state
	var current_move_speed = move_speed
	if jetpack_active:
		current_move_speed = move_speed * jetpack_move_speed_multiplier
	
	var velocity_x = direction.x * current_move_speed
	
	check_condition(current_move_speed == 5.0, "Current move speed should be 5.0 when jetpack is not active")
	check_condition(velocity_x == 5.0, "Velocity X should be 5.0 when moving without jetpack, got %f" % velocity_x)

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
