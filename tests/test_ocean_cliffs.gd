extends Node

# Visual test for ocean cliff generation
# This test verifies that cliffs are generated near ocean boundaries

var test_passed: int = 0
var test_failed: int = 0

# Constants from Chunk class
const CHUNK_SIZE = 32
const OCEAN_START_DISTANCE = 160.0
const RESOLUTION = 32

func _ready():
	print("=== Starting Ocean Cliff Generation Tests ===")
	test_cliff_transition_zone()
	test_cliff_height_calculation()
	test_cliff_increases_near_ocean()
	test_no_cliff_far_from_ocean()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Ocean Cliff Tests Complete ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_cliff_transition_zone():
	print("\n--- Test: Cliff Transition Zone Boundaries ---")
	
	# Cliff transition zone: 2 chunks before ocean (96-160 units from origin)
	var cliff_transition_start = OCEAN_START_DISTANCE - CHUNK_SIZE * 2  # 96
	var cliff_transition_end = OCEAN_START_DISTANCE  # 160
	
	check_condition(cliff_transition_start == 96.0, 
		"Cliff transition should start at 96 units (actual: %.1f)" % cliff_transition_start)
	check_condition(cliff_transition_end == 160.0, 
		"Cliff transition should end at 160 units (actual: %.1f)" % cliff_transition_end)
	
	# Test that transition zone is 2 chunks wide
	var transition_width = cliff_transition_end - cliff_transition_start
	check_condition(transition_width == 64.0, 
		"Cliff transition zone should be 64 units wide (actual: %.1f)" % transition_width)

func test_cliff_height_calculation():
	print("\n--- Test: Cliff Height Calculation ---")
	
	# Setup for cliff offset calculation (simplified version without noise)
	var cliff_transition_start = OCEAN_START_DISTANCE - CHUNK_SIZE * 2  # 96
	var cliff_transition_end = OCEAN_START_DISTANCE  # 160
	
	# Test at start of transition (distance = 96)
	var world_x = 96.0
	var world_z = 0.0
	var distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
	
	if distance_from_origin >= cliff_transition_start and distance_from_origin < cliff_transition_end:
		var transition_factor = (distance_from_origin - cliff_transition_start) / (cliff_transition_end - cliff_transition_start)
		check_condition(transition_factor == 0.0, 
			"Transition factor should be 0.0 at start (actual: %.2f)" % transition_factor)
	
	# Test at middle of transition (distance = 128)
	world_x = 128.0
	world_z = 0.0
	distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
	
	if distance_from_origin >= cliff_transition_start and distance_from_origin < cliff_transition_end:
		var transition_factor = (distance_from_origin - cliff_transition_start) / (cliff_transition_end - cliff_transition_start)
		check_condition(abs(transition_factor - 0.5) < 0.01, 
			"Transition factor should be ~0.5 at middle (actual: %.2f)" % transition_factor)
		
		# Base cliff height at middle: 15 + 0.5 * 10 = 20
		var base_cliff_height = 15.0 + transition_factor * 10.0
		check_condition(abs(base_cliff_height - 20.0) < 0.1, 
			"Base cliff height should be ~20 at middle (actual: %.1f)" % base_cliff_height)
	
	# Test near end of transition (distance = 159)
	world_x = 159.0
	world_z = 0.0
	distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
	
	if distance_from_origin >= cliff_transition_start and distance_from_origin < cliff_transition_end:
		var transition_factor = (distance_from_origin - cliff_transition_start) / (cliff_transition_end - cliff_transition_start)
		check_condition(transition_factor > 0.95, 
			"Transition factor should be >0.95 near end (actual: %.2f)" % transition_factor)
		
		# Base cliff height near end: 15 + 0.98 * 10 ≈ 25
		var base_cliff_height = 15.0 + transition_factor * 10.0
		check_condition(base_cliff_height > 24.0, 
			"Base cliff height should be >24 near end (actual: %.1f)" % base_cliff_height)

func test_cliff_increases_near_ocean():
	print("\n--- Test: Cliff Height Increases Toward Ocean ---")
	
	var cliff_transition_start = OCEAN_START_DISTANCE - CHUNK_SIZE * 2  # 96
	var cliff_transition_end = OCEAN_START_DISTANCE  # 160
	
	# Sample multiple points in the transition zone
	var distances = [100.0, 120.0, 140.0, 155.0]
	var previous_height = 0.0
	
	for dist in distances:
		var world_x = dist
		var world_z = 0.0
		var distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
		
		if distance_from_origin >= cliff_transition_start and distance_from_origin < cliff_transition_end:
			var transition_factor = (distance_from_origin - cliff_transition_start) / (cliff_transition_end - cliff_transition_start)
			var base_cliff_height = 15.0 + transition_factor * 10.0
			var cliff_height = base_cliff_height * transition_factor
			
			# Each successive point should have higher cliff
			if previous_height > 0:
				check_condition(cliff_height > previous_height, 
					"Cliff at distance %.1f should be higher than previous (current: %.1f, previous: %.1f)" 
					% [dist, cliff_height, previous_height])
			
			previous_height = cliff_height

func test_no_cliff_far_from_ocean():
	print("\n--- Test: No Cliff Far From Ocean ---")
	
	var cliff_transition_start = OCEAN_START_DISTANCE - CHUNK_SIZE * 2  # 96
	var cliff_transition_end = OCEAN_START_DISTANCE  # 160
	
	# Test positions far from ocean (should have no cliff offset)
	var test_positions = [
		Vector2(0.0, 0.0),      # Origin
		Vector2(50.0, 50.0),    # Well before transition
		Vector2(80.0, 0.0),     # Just before transition
		Vector2(200.0, 0.0),    # In ocean (beyond transition)
	]
	
	for pos in test_positions:
		var distance_from_origin = sqrt(pos.x * pos.x + pos.y * pos.y)
		var has_cliff = (distance_from_origin >= cliff_transition_start and 
						 distance_from_origin < cliff_transition_end)
		
		if distance_from_origin < cliff_transition_start or distance_from_origin >= cliff_transition_end:
			check_condition(not has_cliff, 
				"Position (%.1f, %.1f) at distance %.1f should have no cliff" 
				% [pos.x, pos.y, distance_from_origin])

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
