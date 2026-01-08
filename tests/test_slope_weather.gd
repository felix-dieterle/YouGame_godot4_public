extends Node

# Test suite for new features (slope restriction and weather)
const CHUNK = preload("res://scripts/chunk.gd")
const WorldManager = preload("res://scripts/world_manager.gd")

func _ready():
	print("=== Starting Slope and Weather Tests ===")
	test_slope_calculation()
	test_slope_retrieval()
	print("=== All Tests Completed ===")
	get_tree().quit()

func test_slope_calculation():
	print("\n--- Test: Slope Calculation ---")
	
	var seed_value = 12345
	var chunk = CHUNK.new(0, 0, seed_value)
	chunk.generate()
	
	# Test that slope calculation method exists and returns valid values
	var test_positions = [
		Vector2(CHUNK.CHUNK_SIZE / 2, CHUNK.CHUNK_SIZE / 2),  # Center
		Vector2(5.0, 5.0),  # Near corner
		Vector2(CHUNK.CHUNK_SIZE - 5.0, CHUNK.CHUNK_SIZE - 5.0)  # Opposite corner
	]
	
	var all_valid = true
	for pos in test_positions:
		var slope = chunk.get_slope_at_world_pos(pos.x, pos.y)
		if slope < 0 or slope > 90:
			print("FAIL: Invalid slope %.2f at position (%.1f, %.1f)" % [slope, pos.x, pos.y])
			all_valid = false
		else:
			print("  Slope at (%.1f, %.1f): %.2f degrees" % [pos.x, pos.y, slope])
	
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
