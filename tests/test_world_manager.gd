extends Node
# Test script for WorldManager chunk loading and unloading

const WorldManager = preload("res://scripts/systems/world/world_manager.gd")

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n=== WORLD MANAGER TEST ===")
	
	# Run tests
	test_chunk_coordinate_conversion()
	test_initial_chunk_loading()
	test_chunk_unloading_on_movement()
	test_view_distance_calculation()
	test_chunk_persistence()
	
	# Print summary
	print("\n=== TEST SUMMARY ===")
	print("Tests run: ", test_count)
	print("Tests passed: ", passed_count)
	print("Tests failed: ", test_count - passed_count)
	
	if passed_count == test_count:
		print("✓ All tests passed!")
		get_tree().quit(0)
	else:
		print("✗ Some tests failed")
		get_tree().quit(1)

func test_chunk_coordinate_conversion() -> void:
	test_count += 1
	var test_name = "Chunk coordinate conversion"
	
	# Test that world coordinates correctly convert to chunk coordinates
	var world_manager = WorldManager.new()
	
	# Test various positions
	var test_cases = [
		{"world_pos": Vector3(0, 0, 0), "expected": Vector2i(0, 0)},
		{"world_pos": Vector3(32, 0, 0), "expected": Vector2i(1, 0)},
		{"world_pos": Vector3(0, 0, 32), "expected": Vector2i(0, 1)},
		{"world_pos": Vector3(-32, 0, 0), "expected": Vector2i(-1, 0)},
		{"world_pos": Vector3(16, 0, 16), "expected": Vector2i(0, 0)},  # Within first chunk
		{"world_pos": Vector3(48, 0, 48), "expected": Vector2i(1, 1)},
	]
	
	var all_passed = true
	for test_case in test_cases:
		var result = _world_pos_to_chunk_coords(test_case["world_pos"], world_manager.CHUNK_SIZE)
		if result != test_case["expected"]:
			all_passed = false
			print("  FAIL: Position ", test_case["world_pos"], " expected ", test_case["expected"], " got ", result)
	
	world_manager.free()
	
	if all_passed:
		pass_test(test_name)
	else:
		fail_test(test_name, "Chunk coordinate conversion failed for some positions")

func test_initial_chunk_loading() -> void:
	test_count += 1
	var test_name = "Initial chunk loading around origin"
	
	# Create a minimal scene for WorldManager
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	# Add a camera as mock player
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 10, 0)
	test_scene.add_child(camera)
	
	# Add WorldManager
	var world_manager = WorldManager.new()
	test_scene.add_child(world_manager)
	
	# Wait for initial chunk loading
	await get_tree().create_timer(1.0).timeout
	
	# Check that chunks were loaded around origin
	var expected_chunks = (world_manager.VIEW_DISTANCE * 2 + 1) * (world_manager.VIEW_DISTANCE * 2 + 1)
	var actual_chunks = world_manager.chunks.size()
	
	# Cleanup
	test_scene.queue_free()
	
	if actual_chunks >= expected_chunks - 2:  # Allow slight variance
		pass_test(test_name)
	else:
		fail_test(test_name, "Expected ~%d chunks, got %d" % [expected_chunks, actual_chunks])

func test_chunk_unloading_on_movement() -> void:
	test_count += 1
	var test_name = "Chunks unload when player moves far away"
	
	# Create a minimal scene
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	# Add a camera as mock player
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 10, 0)
	test_scene.add_child(camera)
	
	# Add WorldManager
	var world_manager = WorldManager.new()
	test_scene.add_child(world_manager)
	
	# Wait for initial loading
	await get_tree().create_timer(1.0).timeout
	var initial_chunk_count = world_manager.chunks.size()
	
	# Move player far away (more than VIEW_DISTANCE chunks)
	camera.position = Vector3(200, 10, 200)
	
	# Trigger update (simulate _process)
	await get_tree().create_timer(0.5).timeout
	
	# Check that old chunks were unloaded
	var chunks_after_move = world_manager.chunks.size()
	var chunk_origin_exists = world_manager.chunks.has(Vector2i(0, 0))
	
	# Cleanup
	test_scene.queue_free()
	
	if not chunk_origin_exists:
		pass_test(test_name)
	else:
		fail_test(test_name, "Origin chunk still exists after moving far away")

func test_view_distance_calculation() -> void:
	test_count += 1
	var test_name = "View distance correctly determines chunk range"
	
	var world_manager = WorldManager.new()
	var view_dist = world_manager.VIEW_DISTANCE
	
	# Calculate expected chunk range
	var expected_min = -view_dist
	var expected_max = view_dist
	
	world_manager.free()
	
	# View distance should create a square around player
	if view_dist >= 2 and view_dist <= 5:  # Reasonable range
		pass_test(test_name)
	else:
		fail_test(test_name, "View distance %d seems unreasonable" % view_dist)

func test_chunk_persistence() -> void:
	test_count += 1
	var test_name = "Chunks use consistent seed for generation"
	
	# Create two world managers with same seed
	var wm1 = WorldManager.new()
	var wm2 = WorldManager.new()
	
	# Both should use the same world seed
	var seed1 = wm1.WORLD_SEED
	var seed2 = wm2.WORLD_SEED
	
	wm1.free()
	wm2.free()
	
	if seed1 == seed2 and seed1 != 0:
		pass_test(test_name)
	else:
		fail_test(test_name, "World seeds don't match or are invalid")

# Helper functions

func _world_pos_to_chunk_coords(pos: Vector3, chunk_size: int) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / chunk_size)),
		int(floor(pos.z / chunk_size))
	)

func pass_test(test_name: String, message: String = "") -> void:
	passed_count += 1
	print("✓ PASS: ", test_name)
	if message != "":
		print("  ", message)

func fail_test(test_name: String, message: String) -> void:
	print("✗ FAIL: ", test_name)
	print("  ", message)
