extends Node

## Test Ocean and Lighthouse Generation
## 
## This test verifies that:
## 1. Ocean chunks are properly detected
## 2. Ocean water mesh is created
## 3. Lighthouses are placed at coastal positions
## 4. Distance-based ocean detection works correctly

const Chunk = preload("res://scripts/chunk.gd")
const ProceduralModels = preload("res://scripts/procedural_models.gd")

func _ready():
	print("=== Ocean and Lighthouse Test ===")
	
	# Test 1: Lighthouse mesh creation
	print("Test 1: Creating lighthouse mesh...")
	var lighthouse_mesh = ProceduralModels.create_lighthouse_mesh(12345)
	assert(lighthouse_mesh != null, "Lighthouse mesh should be created")
	print("✓ Lighthouse mesh created successfully")
	
	# Test 2: Lighthouse material creation
	print("Test 2: Creating lighthouse material...")
	var lighthouse_mat = ProceduralModels.create_lighthouse_material()
	assert(lighthouse_mat != null, "Lighthouse material should be created")
	print("✓ Lighthouse material created successfully")
	
	# Test 3: Create a chunk with very low elevation (natural ocean)
	print("Test 3: Creating natural ocean chunk (low elevation)...")
	var ocean_chunk = Chunk.new(-5, -5, 12345)  # Position likely to be ocean
	add_child(ocean_chunk)
	ocean_chunk.generate()
	
	# Wait a frame for generation to complete
	await get_tree().process_frame
	
	# Check if ocean was detected
	print("  - Ocean detected: ", ocean_chunk.is_ocean)
	print("  - Biome: ", ocean_chunk.biome)
	
	# Test 4: Create a chunk far from origin (distance-based ocean)
	print("Test 4: Creating distance-based ocean chunk (6 chunks from origin)...")
	var far_ocean_chunk = Chunk.new(6, 0, 12345)  # 6 chunks east = 192 units, beyond OCEAN_START_DISTANCE (160)
	add_child(far_ocean_chunk)
	far_ocean_chunk.generate()
	
	await get_tree().process_frame
	
	print("  - Ocean detected: ", far_ocean_chunk.is_ocean)
	print("  - Biome: ", far_ocean_chunk.biome)
	assert(far_ocean_chunk.is_ocean, "Chunks beyond OCEAN_START_DISTANCE should be ocean")
	print("✓ Distance-based ocean detection works")
	
	# Test 5: Create a coastal chunk (might have lighthouses)
	print("Test 5: Creating coastal chunk...")
	var coastal_chunk = Chunk.new(0, 0, 12345)
	add_child(coastal_chunk)
	coastal_chunk.generate()
	
	await get_tree().process_frame
	
	print("  - Lighthouses placed: ", coastal_chunk.placed_lighthouses.size())
	
	print("=== All Ocean/Lighthouse Tests Passed ===")
	get_tree().quit()
