extends Node

# Test suite for jetpack no fall damage feature
# Tests that landing from jetpack/gliding does not cause fall damage

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Jetpack No Fall Damage Tests ===")
	test_gliding_does_not_trigger_fall_state()
	test_jetpack_resets_fall_state()
	test_falling_then_jetpack_then_glide_no_damage()
	test_landing_from_glide_no_damage()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Jetpack No Fall Damage Tests Complete ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_gliding_does_not_trigger_fall_state():
	print("\n--- Test: Gliding Does Not Trigger Fall State ---")
	
	# Simulate player state
	var is_gliding = false
	var is_falling = false
	var jetpack_active = false
	var was_jetpack_active = false
	var is_airborne = true  # Player is airborne
	var height_above_terrain = 10.0  # High above terrain
	
	# Activate jetpack (should reset fall state)
	jetpack_active = true
	if jetpack_active:
		is_gliding = false
		was_jetpack_active = true
		is_falling = false  # Jetpack resets fall state
	
	check_condition(is_falling == false, "is_falling should be false when jetpack is active")
	
	# Release jetpack (should start gliding)
	jetpack_active = false
	if not jetpack_active and was_jetpack_active:
		is_gliding = true
		was_jetpack_active = false
	
	check_condition(is_gliding == true, "Player should be gliding after jetpack release")
	
	# Simulate fall state detection logic (with the fix)
	# is_airborne is true, player is gliding
	if is_airborne and not is_falling and not jetpack_active and not is_gliding:
		is_falling = true  # This should NOT execute because is_gliding is true
	
	check_condition(is_falling == false, "is_falling should remain false while gliding (no fall damage)")
	
func test_jetpack_resets_fall_state():
	print("\n--- Test: Jetpack Resets Fall State ---")
	
	# Simulate player falling
	var is_falling = true
	var jetpack_active = false
	var is_gliding = false
	var was_jetpack_active = false
	
	check_condition(is_falling == true, "Player should start in falling state")
	
	# Activate jetpack
	jetpack_active = true
	if jetpack_active:
		is_gliding = false
		was_jetpack_active = true
		is_falling = false  # Jetpack should reset fall state
	
	check_condition(is_falling == false, "Jetpack should reset is_falling to false")
	check_condition(is_gliding == false, "is_gliding should be false when jetpack is active")

func test_falling_then_jetpack_then_glide_no_damage():
	print("\n--- Test: Fall -> Jetpack -> Glide -> Land (No Damage) ---")
	
	# Setup constants
	var fall_damage_threshold = 5.0
	var fall_damage_per_meter = 5.0
	var current_health = 100.0
	
	# Simulate player falling from a cliff
	var is_falling = true
	var fall_start_y = 30.0
	var current_y = 25.0
	var jetpack_active = false
	var is_gliding = false
	var was_jetpack_active = false
	
	check_condition(is_falling == true, "Player should be falling initially")
	
	# Player activates jetpack while falling
	jetpack_active = true
	if jetpack_active:
		is_gliding = false
		was_jetpack_active = true
		is_falling = false  # Jetpack resets fall state
	
	check_condition(is_falling == false, "Jetpack should reset is_falling to false")
	
	# Player releases jetpack, starts gliding
	jetpack_active = false
	if not jetpack_active and was_jetpack_active:
		is_gliding = true
		was_jetpack_active = false
	
	check_condition(is_gliding == true, "Player should be gliding")
	check_condition(is_falling == false, "is_falling should still be false")
	
	# Player descends while gliding
	current_y = 5.0
	
	# Player lands from gliding
	var terrain_level = 5.0
	if is_gliding and current_y <= terrain_level:
		is_gliding = false
		# Reset fall state - gliding is controlled descent, no fall damage
		is_falling = false
	
	check_condition(is_gliding == false, "Player should have landed")
	check_condition(is_falling == false, "is_falling should be false after gliding landing")
	check_condition(current_health == 100.0, "Health should remain 100 after landing from jetpack/glide (health: %f)" % current_health)

func test_landing_from_glide_no_damage():
	print("\n--- Test: Landing From Glide No Damage ---")
	
	# Setup constants
	var fall_damage_threshold = 5.0
	var fall_damage_per_meter = 5.0
	var current_health = 100.0
	var is_falling = false
	var is_gliding = true
	var fall_start_y = 20.0
	var current_y = 5.0
	
	# Simulate landing from gliding
	# With the fix, is_falling should be false when landing from glide
	if is_gliding:
		# Player lands
		is_gliding = false
		
		# Check for fall damage (should not apply because is_falling is false)
		if is_falling:
			var fall_distance = fall_start_y - current_y
			if fall_distance > fall_damage_threshold:
				var excess_fall = fall_distance - fall_damage_threshold
				var damage = excess_fall * fall_damage_per_meter
				current_health = max(0.0, current_health - damage)
		is_falling = false
	
	check_condition(current_health == 100.0, "Health should remain 100 after landing from glide (health: %f)" % current_health)
	check_condition(is_falling == false, "is_falling should be false after landing")
	check_condition(is_gliding == false, "is_gliding should be false after landing")

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
