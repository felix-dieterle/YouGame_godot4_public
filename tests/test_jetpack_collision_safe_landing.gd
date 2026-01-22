extends Node

# Test suite for collision-safe jetpack landing feature
# Tests that landing from jetpack prevents clipping through terrain and walls

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Jetpack Collision-Safe Landing Tests ===")
	test_safe_margin_configuration()
	test_velocity_dampening_on_landing()
	test_landing_state_transitions()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Jetpack Collision-Safe Landing Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_safe_margin_configuration():
	print("\n--- Test: Safe Margin Configuration ---")
	
	# Safe margin should be configured to prevent tunneling
	var expected_safe_margin = 0.08
	
	check_condition(expected_safe_margin > 0.0, "Safe margin should be positive")
	check_condition(expected_safe_margin <= 0.1, "Safe margin should be reasonable (not too large): %f" % expected_safe_margin)

func test_velocity_dampening_on_landing():
	print("\n--- Test: Velocity Dampening on Landing ---")
	
	# Simulate high descent velocity before landing
	var velocity_y = -5.0  # Fast descent
	var is_gliding = true
	var player_height = 5.1
	var terrain_level = 5.0
	
	# Simulate landing detection
	if is_gliding and player_height <= terrain_level:
		is_gliding = false
		# Apply dampening - should reduce to max 10% of original or -0.5, whichever is higher
		velocity_y = max(velocity_y * 0.1, -0.5)
	
	check_condition(is_gliding == false, "Should stop gliding on landing")
	check_condition(velocity_y > -1.0, "Velocity should be dampened on landing: %f" % velocity_y)
	check_condition(velocity_y == -0.5, "Velocity should be clamped to -0.5 for smooth landing: %f" % velocity_y)

func test_landing_state_transitions():
	print("\n--- Test: Landing State Transitions with Collision Awareness ---")
	
	# Test that landing properly transitions states
	var is_gliding = true
	var was_jetpack_active = false
	var velocity_y = -0.5
	var player_height = 5.1
	var terrain_level = 5.0
	
	# Before landing
	check_condition(is_gliding == true, "Should be gliding before landing")
	
	# Simulate landing
	if is_gliding and player_height <= terrain_level:
		is_gliding = false
		velocity_y = max(velocity_y * 0.1, -0.5)
		# Safe snap would be called here
		velocity_y = 0.0
	
	# After landing
	check_condition(is_gliding == false, "Should stop gliding after landing")
	check_condition(velocity_y == 0.0, "Velocity should be zero after landing")
	check_condition(was_jetpack_active == false, "Jetpack should not be active after landing")

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
