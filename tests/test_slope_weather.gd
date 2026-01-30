extends Node

# Test suite for new features (slope restriction and weather)
const CHUNK = preload("res://scripts/systems/world/chunk.gd")
const WorldManager = preload("res://scripts/systems/world/world_manager.gd")

func _ready():
	print("=== Starting Slope and Weather Tests ===")
	test_slope_calculation()
	test_slope_retrieval()
	test_slope_gradient()
	print("=== All Tests Completed ===")
	get_tree().quit()

func test_slope_calculation():
	print("\n--- Test: Slope Calculation ---")
	
	var seed_value = 12345
	var chunk = CHUNK.new(0, 0, seed_value)
	chunk.generate()
	
	# Test that slope calculation method exists and returns valid values
	var test_positions = [
		{"x": CHUNK.CHUNK_SIZE / 2, "z": CHUNK.CHUNK_SIZE / 2},  # Center
		{"x": 5.0, "z": 5.0},  # Near corner
		{"x": CHUNK.CHUNK_SIZE - 5.0, "z": CHUNK.CHUNK_SIZE - 5.0}  # Opposite corner
	]
	
	var all_valid = true
	for pos in test_positions:
		var slope = chunk.get_slope_at_world_pos(pos.x, pos.z)
		if slope < 0 or slope > 90:
			print("FAIL: Invalid slope %.2f at position (%.1f, %.1f)" % [slope, pos.x, pos.z])
			all_valid = false
		else:
			print("  Slope at (%.1f, %.1f): %.2f degrees" % [pos.x, pos.z, slope])
	
	if all_valid:
		print("PASS: Slope calculation returns valid values")
	else:
		print("FAIL: Some slope calculations returned invalid values")
	
	chunk.free()

func test_slope_retrieval():
	print("\n--- Test: Slope Retrieval via WorldManager ---")
	
	# Create a minimal world manager setup
	var world_manager = WorldManager.new()
	var test_chunk = CHUNK.new(0, 0, 12345)
	test_chunk.generate()
	test_chunk.position = Vector3(0, 0, 0)
	
	# Manually add chunk to world manager
	world_manager.chunks[Vector2i(0, 0)] = test_chunk
	
	# Test slope retrieval
	var test_position = Vector3(16.0, 0.0, 16.0)  # Center of chunk
	var slope = world_manager.get_slope_at_position(test_position)
	
	if slope >= 0 and slope <= 90:
		print("PASS: WorldManager.get_slope_at_position returns valid slope: %.2f degrees" % slope)
	else:
		print("FAIL: WorldManager.get_slope_at_position returned invalid slope: %.2f" % slope)
	
	# Test position outside chunks
	var slope_outside = world_manager.get_slope_at_position(Vector3(1000, 0, 1000))
	if slope_outside == 0.0:
		print("PASS: Slope outside chunks returns 0.0")
	else:
		print("FAIL: Slope outside chunks should return 0.0, got %.2f" % slope_outside)
	
	# Cleanup
	test_chunk.free()
	world_manager.free()

func test_slope_gradient():
	print("\n--- Test: Slope Gradient Calculation ---")
	
	var seed_value = 12345
	var chunk = CHUNK.new(0, 0, seed_value)
	chunk.generate()
	
	# Test gradient calculation at various positions
	var test_positions = [
		{"x": CHUNK.CHUNK_SIZE / 2, "z": CHUNK.CHUNK_SIZE / 2},  # Center
		{"x": 5.0, "z": 5.0},  # Near corner
	]
	
	var all_valid = true
	for pos in test_positions:
		var gradient = chunk.get_slope_gradient_at_world_pos(pos.x, pos.z)
		
		# Gradient should be a Vector3 with y=0
		if gradient.y != 0:
			print("FAIL: Gradient y component should be 0, got %.2f" % gradient.y)
			all_valid = false
		else:
			print("  Gradient at (%.1f, %.1f): (%.3f, %.3f, %.3f)" % [pos.x, pos.z, gradient.x, gradient.y, gradient.z])
		
		# Additional check: gradient length should be reasonable (not NaN or infinite)
		var gradient_length = gradient.length()
		if is_nan(gradient_length) or is_inf(gradient_length):
			print("FAIL: Gradient has invalid length at (%.1f, %.1f)" % [pos.x, pos.z])
			all_valid = false
	
	if all_valid:
		print("PASS: Slope gradient calculation returns valid values")
	else:
		print("FAIL: Some slope gradient calculations returned invalid values")
	
	chunk.free()
	
	# Test gradient via WorldManager
	print("\n--- Test: Slope Gradient via WorldManager ---")
	var world_manager = WorldManager.new()
	var test_chunk = CHUNK.new(0, 0, 12345)
	test_chunk.generate()
	test_chunk.position = Vector3(0, 0, 0)
	world_manager.chunks[Vector2i(0, 0)] = test_chunk
	
	var test_position = Vector3(16.0, 0.0, 16.0)
	var gradient = world_manager.get_slope_gradient_at_position(test_position)
	
	if gradient.y == 0:
		print("PASS: WorldManager.get_slope_gradient_at_position returns valid gradient")
	else:
		print("FAIL: WorldManager.get_slope_gradient_at_position returned invalid gradient")
	
	# Test position outside chunks
	var gradient_outside = world_manager.get_slope_gradient_at_position(Vector3(1000, 0, 1000))
	if gradient_outside == Vector3.ZERO:
		print("PASS: Gradient outside chunks returns Vector3.ZERO")
	else:
		print("FAIL: Gradient outside chunks should return Vector3.ZERO, got %s" % str(gradient_outside))
	
	# Cleanup
	test_chunk.free()
	world_manager.free()
