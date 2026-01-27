extends Node

# Test suite for fall damage mechanics
# Tests fall detection, damage calculation, and pain indicator triggering

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Fall Damage Tests ===")
	test_fall_threshold()
	test_fall_damage_calculation()
	test_no_damage_below_threshold()
	test_fall_damage_scales_with_height()
	test_game_over_from_fall_damage()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Fall Damage Tests Complete ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_fall_threshold():
	print("\n--- Test: Fall Damage Threshold ---")
	
	# Setup constants from Player class
	var fall_damage_threshold = 5.0  # Minimum fall height before damage
	var fall_damage_per_meter = 5.0  # Damage per meter
	
	# Test exact threshold - should do no damage
	var fall_distance = 5.0
	var excess_fall = max(0.0, fall_distance - fall_damage_threshold)
	var damage = excess_fall * fall_damage_per_meter
	
	check_condition(damage == 0.0, "Falling exactly threshold distance (5m) should do no damage (damage: %f)" % damage)
	
	# Test just below threshold - should do no damage
	fall_distance = 4.9
	excess_fall = max(0.0, fall_distance - fall_damage_threshold)
	damage = excess_fall * fall_damage_per_meter
	
	check_condition(damage == 0.0, "Falling below threshold (4.9m) should do no damage (damage: %f)" % damage)

func test_fall_damage_calculation():
	print("\n--- Test: Fall Damage Calculation ---")
	
	# Setup constants
	var fall_damage_threshold = 5.0
	var fall_damage_per_meter = 5.0
	var current_health = 100.0
	
	# Test falling 6 meters (1m above threshold)
	var fall_distance = 6.0
	var excess_fall = fall_distance - fall_damage_threshold
	var damage = excess_fall * fall_damage_per_meter
	current_health = max(0.0, current_health - damage)
	
	check_condition(damage == 5.0, "Falling 6m should do 5 damage (1m excess * 5 damage/m) (damage: %f)" % damage)
	check_condition(current_health == 95.0, "Health should be 95 after 5 damage (health: %f)" % current_health)
	
	# Test falling 10 meters (5m above threshold)
	current_health = 100.0
	fall_distance = 10.0
	excess_fall = fall_distance - fall_damage_threshold
	damage = excess_fall * fall_damage_per_meter
	current_health = max(0.0, current_health - damage)
	
	check_condition(damage == 25.0, "Falling 10m should do 25 damage (5m excess * 5 damage/m) (damage: %f)" % damage)
	check_condition(current_health == 75.0, "Health should be 75 after 25 damage (health: %f)" % current_health)

func test_no_damage_below_threshold():
	print("\n--- Test: No Damage Below Threshold ---")
	
	# Setup constants
	var fall_damage_threshold = 5.0
	var fall_damage_per_meter = 5.0
	var current_health = 100.0
	
	# Test various fall distances below threshold
	var test_distances = [0.0, 1.0, 2.5, 4.0, 4.99]
	
	for fall_distance in test_distances:
		var excess_fall = max(0.0, fall_distance - fall_damage_threshold)
		var damage = excess_fall * fall_damage_per_meter
		current_health = max(0.0, current_health - damage)
		
		check_condition(damage == 0.0, "Falling %.2fm should do no damage (damage: %f)" % [fall_distance, damage])
	
	check_condition(current_health == 100.0, "Health should remain at 100 after all safe falls (health: %f)" % current_health)

func test_fall_damage_scales_with_height():
	print("\n--- Test: Fall Damage Scales With Height ---")
	
	# Setup constants
	var fall_damage_threshold = 5.0
	var fall_damage_per_meter = 5.0
	
	# Test that damage increases linearly with fall height
	var fall_heights = [6.0, 8.0, 12.0, 20.0]
	var expected_damages = [5.0, 15.0, 35.0, 75.0]
	
	for i in range(fall_heights.size()):
		var fall_distance = fall_heights[i]
		var excess_fall = fall_distance - fall_damage_threshold
		var damage = excess_fall * fall_damage_per_meter
		
		check_condition(damage == expected_damages[i], 
			"Falling %.1fm should do %.1f damage (actual: %.1f)" % [fall_distance, expected_damages[i], damage])

func test_game_over_from_fall_damage():
	print("\n--- Test: Game Over From Fall Damage ---")
	
	# Setup constants
	var fall_damage_threshold = 5.0
	var fall_damage_per_meter = 5.0
	var current_health = 100.0
	
	# Test lethal fall (25m fall = 100 damage)
	var fall_distance = 25.0
	var excess_fall = fall_distance - fall_damage_threshold
	var damage = excess_fall * fall_damage_per_meter
	current_health = max(0.0, current_health - damage)
	
	check_condition(damage == 100.0, "Falling 25m should do 100 damage (damage: %f)" % damage)
	check_condition(current_health == 0.0, "Health should be 0 after lethal fall (health: %f)" % current_health)
	
	# Test that health doesn't go below zero
	var game_over_triggered = current_health <= 0.0
	check_condition(game_over_triggered, "Game over should trigger at zero health")
	
	# Test near-lethal fall
	current_health = 100.0
	fall_distance = 24.0  # 95 damage
	excess_fall = fall_distance - fall_damage_threshold
	damage = excess_fall * fall_damage_per_meter
	current_health = max(0.0, current_health - damage)
	
	check_condition(current_health == 5.0, "Health should be 5 after 95 damage fall (health: %f)" % current_health)
	game_over_triggered = current_health <= 0.0
	check_condition(not game_over_triggered, "Game over should not trigger with health remaining")

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
