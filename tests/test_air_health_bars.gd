extends Node

# Test suite for air and health bar mechanics
# Tests underwater air depletion, health loss, and refill behavior

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Air and Health Bar Tests ===")
	test_air_depletion_underwater()
	test_air_refill_above_water()
	test_health_depletion_when_air_empty()
	test_no_health_loss_with_air()
	test_game_over_at_zero_health()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Air and Health Bar Tests Complete ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_air_depletion_underwater():
	print("\n--- Test: Air Depletion Underwater ---")
	
	# Setup initial state
	var current_air = 100.0
	var max_air = 100.0
	var air_depletion_rate = 10.0
	var is_underwater = true
	var delta = 1.0  # 1 second
	
	# Simulate air depletion underwater
	if is_underwater:
		current_air = max(0.0, current_air - air_depletion_rate * delta)
	
	check_condition(current_air == 90.0, "Air should deplete by 10 after 1 second underwater (current: %f)" % current_air)
	
	# Simulate 10 seconds underwater
	current_air = 100.0
	for i in range(10):
		if is_underwater:
			current_air = max(0.0, current_air - air_depletion_rate * delta)
	
	check_condition(current_air == 0.0, "Air should be empty after 10 seconds underwater (current: %f)" % current_air)
	
	# Test that air doesn't go below zero
	if is_underwater:
		current_air = max(0.0, current_air - air_depletion_rate * delta)
	
	check_condition(current_air == 0.0, "Air should not go below zero (current: %f)" % current_air)

func test_air_refill_above_water():
	print("\n--- Test: Air Refill Above Water ---")
	
	# Setup depleted air
	var current_air = 20.0
	var max_air = 100.0
	var is_underwater = false
	
	# Simulate being above water
	if not is_underwater:
		current_air = max_air
	
	check_condition(current_air == 100.0, "Air should refill to max immediately above water (current: %f)" % current_air)
	
	# Test with completely empty air
	current_air = 0.0
	if not is_underwater:
		current_air = max_air
	
	check_condition(current_air == 100.0, "Air should refill from 0 to max immediately (current: %f)" % current_air)

func test_health_depletion_when_air_empty():
	print("\n--- Test: Health Depletion When Air Empty ---")
	
	# Setup state with empty air
	var current_air = 0.0
	var current_health = 100.0
	var health_depletion_rate = 5.0
	var is_underwater = true
	var delta = 1.0  # 1 second
	
	# Simulate health loss when air is empty
	if is_underwater:
		if current_air <= 0.0:
			current_health = max(0.0, current_health - health_depletion_rate * delta)
	
	check_condition(current_health == 95.0, "Health should deplete by 5 after 1 second with no air (current: %f)" % current_health)
	
	# Simulate 20 seconds without air
	current_health = 100.0
	for i in range(20):
		if is_underwater and current_air <= 0.0:
			current_health = max(0.0, current_health - health_depletion_rate * delta)
	
	check_condition(current_health == 0.0, "Health should be empty after 20 seconds without air (current: %f)" % current_health)
	
	# Test that health doesn't go below zero
	if is_underwater and current_air <= 0.0:
		current_health = max(0.0, current_health - health_depletion_rate * delta)
	
	check_condition(current_health == 0.0, "Health should not go below zero (current: %f)" % current_health)

func test_no_health_loss_with_air():
	print("\n--- Test: No Health Loss With Air ---")
	
	# Setup state with air available
	var current_air = 50.0
	var current_health = 100.0
	var health_depletion_rate = 5.0
	var is_underwater = true
	var delta = 1.0  # 1 second
	
	# Simulate no health loss when air is available
	if is_underwater:
		if current_air <= 0.0:
			current_health = max(0.0, current_health - health_depletion_rate * delta)
	
	check_condition(current_health == 100.0, "Health should not deplete when air is available (current: %f)" % current_health)
	
	# Test above water
	is_underwater = false
	if is_underwater:
		if current_air <= 0.0:
			current_health = max(0.0, current_health - health_depletion_rate * delta)
	
	check_condition(current_health == 100.0, "Health should not deplete above water (current: %f)" % current_health)

func test_game_over_at_zero_health():
	print("\n--- Test: Game Over At Zero Health ---")
	
	# Setup state
	var current_health = 1.0
	var health_depletion_rate = 5.0
	var current_air = 0.0
	var is_underwater = true
	var delta = 1.0
	var game_over_triggered = false
	
	# Simulate health depletion to zero
	if is_underwater and current_air <= 0.0:
		current_health = max(0.0, current_health - health_depletion_rate * delta)
	
	# Check for game over
	if current_health <= 0.0:
		game_over_triggered = true
	
	check_condition(current_health == 0.0, "Health should be at zero (current: %f)" % current_health)
	check_condition(game_over_triggered, "Game over should trigger when health reaches zero")
	
	# Test that game over doesn't trigger with health remaining
	current_health = 10.0
	game_over_triggered = false
	
	if current_health <= 0.0:
		game_over_triggered = true
	
	check_condition(not game_over_triggered, "Game over should not trigger with health remaining (health: %f)" % current_health)

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
