extends Node

# Test suite for chunk generation
const CHUNK = preload("res://scripts/chunk.gd")

func _ready():
	print("=== Starting Chunk Tests ===")
	test_seed_reproducibility()
	test_walkability_percentage()
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
