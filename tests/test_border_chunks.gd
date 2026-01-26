extends Node3D

## Test for border chunk generation and features
##
## This test verifies:
## - Border chunks are detected at correct distance from origin
## - Border chunks have correct biome and landmark type
## - Border features are generated (warning signs, skeletons, dunes, etc.)
## - Border chunks have no trees or green vegetation
## - Player health drains in border chunks

# Preload dependencies
const Chunk = preload("res://scripts/chunk.gd")
const WorldManager = preload("res://scripts/world_manager.gd")
const Player = preload("res://scripts/player.gd")

var world_manager: WorldManager
var player: Player
var test_results: Array = []

func _ready() -> void:
	print("\n=== Border Chunk Test ===")
	
	# Create world manager
	world_manager = WorldManager.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)
	
	# Create player
	player = Player.new()
	player.name = "Player"
	add_child(player)
	
	# Wait for world to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Run tests
	test_border_detection()
	test_border_biome()
	test_border_features()
	test_border_no_vegetation()
	test_border_health_drain()
	
	# Print results
	print_test_results()
	
	# Exit
	get_tree().quit()

func test_border_detection() -> void:
	print("\n--- Testing Border Detection ---")
	
	# Test 1: Chunk at origin should NOT be border
	var origin_chunk = Chunk.new(0, 0, 12345)
	origin_chunk.generate()
	var is_border_origin = origin_chunk.is_border
	
	if not is_border_origin:
		test_results.append({"name": "Origin chunk is not border", "passed": true})
		print("✓ Origin chunk (0, 0) is not border: PASS")
	else:
		test_results.append({"name": "Origin chunk is not border", "passed": false})
		print("✗ Origin chunk (0, 0) incorrectly marked as border: FAIL")
	
	origin_chunk.queue_free()
	
	# Test 2: Chunk at border distance should be border
	# Border starts at 256 units, chunk size is 32, so chunk 8,0 should be border
	var border_chunk = Chunk.new(8, 0, 12345)
	border_chunk.generate()
	var is_border_far = border_chunk.is_border
	
	if is_border_far:
		test_results.append({"name": "Far chunk is border", "passed": true})
		print("✓ Far chunk (8, 0) is border: PASS")
	else:
		test_results.append({"name": "Far chunk is border", "passed": false})
		print("✗ Far chunk (8, 0) not marked as border: FAIL")
	
	border_chunk.queue_free()
	
	# Test 3: Chunk just before border should NOT be border
	# Distance at chunk (7, 0) is 7*32 = 224 < 256, so should not be border
	var near_border_chunk = Chunk.new(7, 0, 12345)
	near_border_chunk.generate()
	var is_border_near = near_border_chunk.is_border
	
	if not is_border_near:
		test_results.append({"name": "Near-border chunk is not border", "passed": true})
		print("✓ Near-border chunk (7, 0) is not border: PASS")
	else:
		test_results.append({"name": "Near-border chunk is not border", "passed": false})
		print("✗ Near-border chunk (7, 0) incorrectly marked as border: FAIL")
	
	near_border_chunk.queue_free()

func test_border_biome() -> void:
	print("\n--- Testing Border Biome ---")
	
	# Create border chunk
	var border_chunk = Chunk.new(10, 10, 12345)
	border_chunk.generate()
	
	# Check biome
	if border_chunk.biome == "border":
		test_results.append({"name": "Border chunk has correct biome", "passed": true})
		print("✓ Border chunk has biome 'border': PASS")
	else:
		test_results.append({"name": "Border chunk has correct biome", "passed": false})
		print("✗ Border chunk has wrong biome '%s': FAIL" % border_chunk.biome)
	
	# Check landmark type
	if border_chunk.landmark_type == "wasteland":
		test_results.append({"name": "Border chunk has correct landmark type", "passed": true})
		print("✓ Border chunk has landmark_type 'wasteland': PASS")
	else:
		test_results.append({"name": "Border chunk has correct landmark type", "passed": false})
		print("✗ Border chunk has wrong landmark_type '%s': FAIL" % border_chunk.landmark_type)
	
	border_chunk.queue_free()

func test_border_features() -> void:
	print("\n--- Testing Border Features ---")
	
	# Create border chunk
	var border_chunk = Chunk.new(12, 12, 12345)
	border_chunk.generate()
	
	# Check for warning signs
	var has_warning_signs = border_chunk.border_warning_signs.size() > 0
	if has_warning_signs:
		test_results.append({"name": "Border chunk has warning signs", "passed": true})
		print("✓ Border chunk has %d warning signs: PASS" % border_chunk.border_warning_signs.size())
	else:
		test_results.append({"name": "Border chunk has warning signs", "passed": false})
		print("✗ Border chunk has no warning signs: FAIL")
	
	# Check for skeletons
	var has_skeletons = border_chunk.border_skeletons.size() > 0
	if has_skeletons:
		test_results.append({"name": "Border chunk has skeletons", "passed": true})
		print("✓ Border chunk has %d skeletons: PASS" % border_chunk.border_skeletons.size())
	else:
		test_results.append({"name": "Border chunk has skeletons", "passed": false})
		print("✗ Border chunk has no skeletons: FAIL")
	
	# Check for dunes
	var has_dunes = border_chunk.border_dunes.size() > 0
	if has_dunes:
		test_results.append({"name": "Border chunk has dunes", "passed": true})
		print("✓ Border chunk has %d dunes: PASS" % border_chunk.border_dunes.size())
	else:
		test_results.append({"name": "Border chunk has dunes", "passed": false})
		print("✗ Border chunk has no dunes: FAIL")
	
	border_chunk.queue_free()

func test_border_no_vegetation() -> void:
	print("\n--- Testing Border No Vegetation ---")
	
	# Create border chunk
	var border_chunk = Chunk.new(10, 10, 12345)
	border_chunk.generate()
	
	# Check that no trees or bushes were placed
	# Trees and bushes are added to placed_objects array
	# Border chunks should not have any vegetation in placed_objects
	var vegetation_count = border_chunk.placed_objects.size()
	var has_no_vegetation = (vegetation_count == 0)
	
	if has_no_vegetation:
		test_results.append({"name": "Border chunk has no vegetation", "passed": true})
		print("✓ Border chunk has no vegetation (placed_objects: %d): PASS" % vegetation_count)
	else:
		test_results.append({"name": "Border chunk has no vegetation", "passed": false})
		print("✗ Border chunk has vegetation (placed_objects: %d): FAIL" % vegetation_count)
	
	border_chunk.queue_free()

func test_border_health_drain() -> void:
	print("\n--- Testing Border Health Drain ---")
	
	# Check that the constant is defined
	var health_drain_rate = Chunk.BORDER_HEALTH_DRAIN_RATE
	if health_drain_rate > 0:
		test_results.append({"name": "Border health drain rate is positive", "passed": true})
		print("✓ Border health drain rate is %f HP/s: PASS" % health_drain_rate)
	else:
		test_results.append({"name": "Border health drain rate is positive", "passed": false})
		print("✗ Border health drain rate is not positive: FAIL")
	
	# Note: Full health drain testing would require running the player in a border chunk
	# which is more complex and requires game loop integration

func print_test_results() -> void:
	print("\n=== Test Summary ===")
	
	var total_tests = test_results.size()
	var passed_tests = 0
	
	for result in test_results:
		if result["passed"]:
			passed_tests += 1
	
	print("Total tests: %d" % total_tests)
	print("Passed: %d" % passed_tests)
	print("Failed: %d" % (total_tests - passed_tests))
	
	if passed_tests == total_tests:
		print("\n✓ All tests passed!")
	else:
		print("\n✗ Some tests failed")
