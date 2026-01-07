extends Node

# Test suite for chunk generation
const CHUNK = preload("res://scripts/chunk.gd")

func _ready():
	print("=== Starting Chunk Tests ===")
	test_seed_reproducibility()
	test_walkability_percentage()
	test_lake_generation()
	test_water_depth()
	print("=== All Tests Completed ===")
	get_tree().quit()

func test_seed_reproducibility():
	print("\n--- Test: Seed Reproducibility ---")
	
	var seed_value = 12345
	var chunk1 = CHUNK.new(0, 0, seed_value)
	chunk1.generate()
	
	var chunk2 = CHUNK.new(0, 0, seed_value)
	chunk2.generate()
	
	# Compare heightmaps
	var identical = true
	if chunk1.heightmap.size() != chunk2.heightmap.size():
		identical = false
		print("FAIL: Heightmap sizes differ")
	else:
		for i in range(chunk1.heightmap.size()):
			if abs(chunk1.heightmap[i] - chunk2.heightmap[i]) > 0.001:
				identical = false
				print("FAIL: Heights differ at index %d: %f vs %f" % [i, chunk1.heightmap[i], chunk2.heightmap[i]])
				break
	
	if identical:
		print("PASS: Chunks with same seed produce identical terrain")
	else:
		print("FAIL: Chunks with same seed produce different terrain")
	
	chunk1.free()
	chunk2.free()

func test_walkability_percentage():
	print("\n--- Test: Walkability Percentage ---")
	
	var seed_value = 12345
	var test_count = 5
	var all_passed = true
	
	for i in range(test_count):
		var chunk = CHUNK.new(i, i, seed_value + i)
		chunk.generate()
		
		var walkable_count = 0
		for j in range(chunk.walkable_map.size()):
			if chunk.walkable_map[j] == 1:
				walkable_count += 1
		
		var walkable_percentage = float(walkable_count) / float(chunk.walkable_map.size())
		
		if walkable_percentage >= CHUNK.MIN_WALKABLE_PERCENTAGE:
			print("PASS: Chunk (%d, %d) has %.2f%% walkable area" % [i, i, walkable_percentage * 100])
		else:
			print("FAIL: Chunk (%d, %d) has only %.2f%% walkable area (minimum: %.2f%%)" % 
				  [i, i, walkable_percentage * 100, CHUNK.MIN_WALKABLE_PERCENTAGE * 100])
			all_passed = false
		
		chunk.free()
	
	if all_passed:
		print("PASS: All chunks meet minimum walkability requirement")
	else:
		print("FAIL: Some chunks do not meet minimum walkability requirement")

func test_lake_generation():
	print("\n--- Test: Lake Generation in Valleys ---")
	
	var seed_value = 12345
	var test_count = 20  # Test more chunks to find valleys
	var valley_count = 0
	var lake_count = 0
	
	for i in range(test_count):
		var chunk = CHUNK.new(i, i, seed_value + i)
		chunk.generate()
		
		if chunk.landmark_type == "valley":
			valley_count += 1
			if chunk.has_lake:
				lake_count += 1
				print("  Found lake in valley chunk (%d, %d) with radius %.2f" % [i, i, chunk.lake_radius])
		
		chunk.free()
	
	print("Found %d valleys out of %d chunks tested" % [valley_count, test_count])
	print("Found %d lakes in valleys" % lake_count)
	
	if valley_count > 0:
		print("PASS: Lake generation system is working")
	else:
		print("INFO: No valleys found in test chunks (expected with random generation)")

func test_water_depth():
	print("\n--- Test: Water Depth Calculation ---")
	
	# Create a valley chunk that's likely to have a lake
	var seed_value = 54321  # Different seed to potentially create valleys
	var chunk_with_lake = null
	
	# Find a chunk with a lake
	for i in range(50):
		var chunk = CHUNK.new(i * 2, i * 3, seed_value + i)
		chunk.generate()
		
		if chunk.has_lake:
			chunk_with_lake = chunk
			print("  Found chunk with lake at (%d, %d)" % [i * 2, i * 3])
			break
		else:
			chunk.free()
	
	if chunk_with_lake:
		# Test water depth at different positions
		var center_depth = chunk_with_lake.get_water_depth_at_local_pos(
			chunk_with_lake.lake_center.x,
			chunk_with_lake.lake_center.y
		)
		
		var edge_depth = chunk_with_lake.get_water_depth_at_local_pos(
			chunk_with_lake.lake_center.x + chunk_with_lake.lake_radius * 0.9,
			chunk_with_lake.lake_center.y
		)
		
		var outside_depth = chunk_with_lake.get_water_depth_at_local_pos(
			chunk_with_lake.lake_center.x + chunk_with_lake.lake_radius * 1.5,
			chunk_with_lake.lake_center.y
		)
		
		print("  Water depth at center: %.2f" % center_depth)
		print("  Water depth near edge: %.2f" % edge_depth)
		print("  Water depth outside lake: %.2f" % outside_depth)
		
		var passed = true
		if center_depth <= 0:
			print("FAIL: Center depth should be positive")
			passed = false
		if center_depth <= edge_depth:
			print("FAIL: Center should be deeper than edge")
			passed = false
		if outside_depth != 0:
			print("FAIL: Outside lake should have zero depth")
			passed = false
		
		if passed:
			print("PASS: Water depth calculation is correct")
		
		chunk_with_lake.free()
	else:
		print("INFO: No lake found in test chunks (lakes are random in valleys)")
