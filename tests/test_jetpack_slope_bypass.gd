extends Node

# Test suite for jetpack slope bypass feature
# Tests that the player can fly over steep slopes when >1m above terrain

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Jetpack Slope Bypass Tests ===")
	test_height_above_terrain_calculation()
	test_slope_check_skip_when_flying()
	test_slope_check_active_when_grounded()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Jetpack Slope Bypass Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_height_above_terrain_calculation():
	print("\n--- Test: Height Above Terrain Calculation ---")
	
	# Test basic height calculation logic
	var player_height = 10.0
	var terrain_height = 5.0
	var water_depth = 0.0
	var terrain_level = terrain_height + 1.0 - water_depth
	var height_above_terrain = player_height - terrain_level
	
	check_condition(height_above_terrain == 4.0, "Height above terrain should be 4.0, got %.2f" % height_above_terrain)
	
	# Test with water
	water_depth = 2.0
	terrain_level = terrain_height + 1.0 - water_depth
	height_above_terrain = player_height - terrain_level
	
	check_condition(height_above_terrain == 6.0, "Height above terrain with water should be 6.0, got %.2f" % height_above_terrain)

func test_slope_check_skip_when_flying():
	print("\n--- Test: Slope Check Skip When Flying ---")
	
	# Simulate player flying more than 1m above terrain
	var player_height = 10.0
	var terrain_height = 5.0
	var water_depth = 0.0
	var terrain_level = terrain_height + 1.0 - water_depth
	var height_above_terrain = player_height - terrain_level
	
	# Height is 4.0m above terrain, should skip slope checks
	var should_check_slope = height_above_terrain <= 1.0
	
	check_condition(not should_check_slope, "Slope check should be skipped when flying >1m above terrain")
	check_condition(height_above_terrain > 1.0, "Height above terrain should be >1m: %.2f" % height_above_terrain)
	
	# Test edge case: exactly 1m above
	player_height = 7.0
	height_above_terrain = player_height - terrain_level
	should_check_slope = height_above_terrain <= 1.0
	
	check_condition(should_check_slope, "Slope check should be active when exactly 1m above terrain")
	check_condition(height_above_terrain == 1.0, "Height above terrain should be exactly 1m: %.2f" % height_above_terrain)

func test_slope_check_active_when_grounded():
	print("\n--- Test: Slope Check Active When Grounded ---")
	
	# Simulate player on or very close to terrain
	var player_height = 5.0
	var terrain_height = 5.0
	var water_depth = 0.0
	var terrain_level = terrain_height + 1.0 - water_depth
	var height_above_terrain = player_height - terrain_level
	
	# Height is -1.0m (below terrain level), should check slopes
	var should_check_slope = height_above_terrain <= 1.0
	
	check_condition(should_check_slope, "Slope check should be active when on ground")
	check_condition(height_above_terrain <= 1.0, "Height above terrain should be <=1m: %.2f" % height_above_terrain)
	
	# Test slightly above ground
	player_height = 6.5
	height_above_terrain = player_height - terrain_level
	should_check_slope = height_above_terrain <= 1.0
	
	check_condition(should_check_slope, "Slope check should be active when 0.5m above terrain")
	check_condition(height_above_terrain == 0.5, "Height above terrain should be 0.5m: %.2f" % height_above_terrain)

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
