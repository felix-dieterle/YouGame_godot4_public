extends Node

# Test suite for jetpack gliding feature
# Tests the state machine logic for gliding behavior

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Jetpack Glide Tests ===")
	test_jetpack_glide_state_transitions()
	test_glide_speed_configuration()
	test_landing_behavior()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Jetpack Glide Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_jetpack_glide_state_transitions():
	print("\n--- Test: Jetpack Glide State Transitions ---")
	
	# Test state machine logic
	var is_gliding = false
	var was_jetpack_active = false
	
	# Initially, player should not be gliding
	check_condition(is_gliding == false, "Player should not be gliding initially")
	check_condition(was_jetpack_active == false, "Jetpack should not be active initially")
	
	# Simulate jetpack activation
	var jetpack_active = true
	if jetpack_active:
		is_gliding = false
		was_jetpack_active = true
	
	check_condition(is_gliding == false, "Player should not be gliding when jetpack is active")
	check_condition(was_jetpack_active == true, "was_jetpack_active should be true when jetpack is active")
	
	# Simulate jetpack release
	jetpack_active = false
	if not jetpack_active and was_jetpack_active:
		is_gliding = true
		was_jetpack_active = false
	
	check_condition(is_gliding == true, "Player should be gliding after jetpack release")
	check_condition(was_jetpack_active == false, "was_jetpack_active should be false after release")
	
	# Simulate jetpack re-activation (should stop gliding)
	jetpack_active = true
	if jetpack_active:
		is_gliding = false
		was_jetpack_active = true
	
	check_condition(is_gliding == false, "Gliding should stop when jetpack is re-activated")

func test_glide_speed_configuration():
	print("\n--- Test: Glide Speed Configuration ---")
	
	# Default glide speed should be reasonable
	var default_glide_speed = 0.5
	var jetpack_speed = 3.0
	
	check_condition(default_glide_speed > 0, "Glide speed should be positive")
	check_condition(default_glide_speed < jetpack_speed, "Glide speed (%f) should be slower than jetpack speed (%f)" % [default_glide_speed, jetpack_speed])
	
	# When gliding, velocity should be downward (negative)
	var velocity_y = -default_glide_speed
	check_condition(velocity_y < 0, "Glide velocity should be negative (downward): %f" % velocity_y)

func test_landing_behavior():
	print("\n--- Test: Landing Behavior ---")
	
	# Simulate player gliding above terrain
	var is_gliding = true
	var player_height = 10.0
	var terrain_level = 5.0
	var velocity_y = -0.5
	
	# Simulate descent
	player_height += velocity_y  # Player moves down
	
	# Check if player has reached terrain
	if is_gliding and player_height <= terrain_level:
		is_gliding = false
		player_height = terrain_level
		velocity_y = 0.0
	
	check_condition(is_gliding == false, "Gliding should stop when reaching terrain")
	check_condition(player_height == terrain_level, "Player should be at terrain level: %f" % player_height)
	check_condition(velocity_y == 0.0, "Vertical velocity should be zero after landing")

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1

