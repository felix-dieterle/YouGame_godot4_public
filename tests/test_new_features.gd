extends Node

# Test suite for new features: biomes, terrain materials, mobile controls
const CHUNK = preload("res://scripts/chunk.gd")

func _ready():
	print("=== Starting New Features Tests ===")
	test_terrain_biomes()
	test_terrain_materials()
	print("=== All New Features Tests Completed ===")
	get_tree().quit()

func test_terrain_biomes():
	print("\n--- Test: Terrain Biomes ---")
	
	var seed_value = 12345
	var test_count = 20
	var biome_counts = {
		"mountain": 0,
		"rocky_hills": 0,
		"grassland": 0
	}
	
	for i in range(test_count):
		var chunk = CHUNK.new(i, i, seed_value + i * 100)
		chunk.generate()
		
		# Count biome types
		if biome_counts.has(chunk.biome):
			biome_counts[chunk.biome] += 1
		
		print("  Chunk (%d, %d): biome=%s, landmark=%s" % [
			i, i, chunk.biome, chunk.landmark_type if chunk.landmark_type else "none"
		])
		
		chunk.free()
	
	print("\nBiome distribution:")
	for biome in biome_counts:
		print("  %s: %d chunks (%.1f%%)" % [biome, biome_counts[biome], biome_counts[biome] * 100.0 / test_count])
	
	# Check that we have variety
	var unique_biomes = 0
	for count in biome_counts.values():
		if count > 0:
			unique_biomes += 1
	
	if unique_biomes >= 2:
		print("PASS: Terrain has multiple biome types")
	else:
		print("FAIL: Terrain should have variety in biome types")

func test_terrain_materials():
	print("\n--- Test: Terrain Material Detection ---")
	
	var seed_value = 12345
	var chunk = CHUNK.new(0, 0, seed_value)
	chunk.generate()
	
	# Sample multiple positions in the chunk
	var materials_found = {}
	var sample_count = 10
	var chunk_center = CHUNK.CHUNK_SIZE / 2.0
	
	for i in range(sample_count):
		var x = (i * CHUNK.CHUNK_SIZE / sample_count) + chunk_center
		var z = chunk_center
		var material = chunk.get_terrain_material_at_world_pos(x, z)
		
		if not materials_found.has(material):
			materials_found[material] = 0
		materials_found[material] += 1
	
	print("  Materials detected:")
	for mat in materials_found:
		print("    %s: %d samples" % [mat, materials_found[mat]])
	
	# Verify that get_terrain_material_at_world_pos returns valid material types
	var valid_materials = ["stone", "rock", "grass"]
	var all_valid = true
	
	for mat in materials_found.keys():
		if not mat in valid_materials:
			print("FAIL: Invalid material type: %s" % mat)
			all_valid = false
	
	if all_valid:
		print("PASS: Terrain material detection returns valid types")
	else:
		print("FAIL: Terrain material detection returned invalid types")
	
	chunk.free()
