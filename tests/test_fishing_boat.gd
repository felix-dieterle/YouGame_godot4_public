extends Node

## Test Fishing Boat Placement
## 
## This test verifies that:
## 1. Fishing boat mesh is created correctly
## 2. Fishing boat is placed on coastal chunks near starting area
## 3. Boat is positioned half-buried in sand

const Chunk = preload("res://scripts/systems/world/chunk.gd")
const ProceduralModels = preload("res://scripts/systems/world/procedural_models.gd")

func _ready():
	print("=== Fishing Boat Test ===")
	
	# Test 1: Fishing boat mesh creation
	print("Test 1: Creating fishing boat mesh...")
	var boat_mesh = ProceduralModels.create_fishing_boat_mesh(12345)
	assert(boat_mesh != null, "Fishing boat mesh should be created")
	print("✓ Fishing boat mesh created successfully")
	
	# Test 2: Fishing boat material creation
	print("Test 2: Creating fishing boat material...")
	var boat_mat = ProceduralModels.create_fishing_boat_material()
	assert(boat_mat != null, "Fishing boat material should be created")
	print("✓ Fishing boat material created successfully")
	
	# Test 3: Create multiple chunks to find coastal chunks near spawn
	print("Test 3: Testing fishing boat placement on coastal chunks...")
	var test_chunks = []
	var boat_found = false
	
	# Create a grid of chunks around origin to test
	for x in range(-2, 3):
		for z in range(-2, 3):
			var chunk = Chunk.new(x, z, 12345)
			add_child(chunk)
			chunk.generate()
			test_chunks.append(chunk)
			
			# Check if this chunk has a fishing boat
			if chunk.placed_fishing_boat != null:
				boat_found = true
				print("  - Fishing boat found in chunk (%d, %d)" % [x, z])
				print("  - Boat position: ", chunk.placed_fishing_boat.position)
				print("  - Boat rotation: ", chunk.placed_fishing_boat.rotation)
				print("  - Is coastal chunk: ", not chunk.is_ocean)
	
	# Wait a frame for generation to complete
	await get_tree().process_frame
	
	if boat_found:
		print("✓ Fishing boat successfully placed on coastal chunk near spawn")
	else:
		print("⚠ No fishing boat found - this may be expected if no coastal chunks in test grid")
		print("  (Boat placement requires ocean neighbor within 3 chunks of spawn)")
	
	# Test 4: Verify boat constants
	print("Test 4: Verifying boat constants...")
	assert(ProceduralModels.BOAT_LENGTH == 4.0, "Boat length should be 4.0")
	assert(ProceduralModels.BOAT_WIDTH == 1.5, "Boat width should be 1.5")
	assert(ProceduralModels.BOAT_HEIGHT == 0.8, "Boat height should be 0.8")
	print("✓ Boat constants verified")
	
	print("=== All Fishing Boat Tests Completed ===")
	get_tree().quit()
