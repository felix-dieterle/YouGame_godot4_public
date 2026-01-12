extends Node

# Test suite for path system
const PathSystem = preload("res://scripts/path_system.gd")

func _ready():
	print("=== Starting Path System Tests ===")
	test_path_generation()
	test_path_continuation()
	test_path_branching()
	test_path_endpoint_detection()
	test_starting_chunk()
	print("=== All Path System Tests Completed ===")
	get_tree().quit()

func test_path_generation():
	print("\n--- Test: Path Generation ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	var chunk_pos = Vector2i(0, 0)
	
	var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	if segments.size() > 0:
		print("PASS: Path segments generated for starting chunk: ", segments.size())
	else:
		print("FAIL: No path segments generated for starting chunk")
	
	# Check that segments are registered
	var total_segments = PathSystem.get_total_segments()
	if total_segments > 0:
		print("PASS: Segments registered in system: ", total_segments)
	else:
		print("FAIL: Segments not registered in system")

func test_path_continuation():
	print("\n--- Test: Path Continuation Across Chunks ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	
	# Generate starting chunk
	var chunk0 = Vector2i(0, 0)
	var segments0 = PathSystem.get_path_segments_for_chunk(chunk0, world_seed)
	
	# Generate neighboring chunks
	var neighbors = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(0, -1)
	]
	
	var continuation_found = false
	for neighbor in neighbors:
		var segments = PathSystem.get_path_segments_for_chunk(neighbor, world_seed)
		if segments.size() > 0:
			continuation_found = true
			print("PASS: Path continuation found in chunk ", neighbor)
	
	if not continuation_found:
		print("INFO: No immediate path continuation (can be random)")

func test_path_branching():
	print("\n--- Test: Path Branching ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 54321  # Different seed for different results
	
	# Generate multiple chunks to increase chance of branches
	var total_branches = 0
	for x in range(-2, 3):
		for z in range(-2, 3):
			var chunk_pos = Vector2i(x, z)
			var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
			
			for segment in segments:
				if segment.next_segments.size() > 0:
					total_branches += 1
	
	if total_branches > 0:
		print("PASS: Found ", total_branches, " branch points")
	else:
		print("INFO: No branches found (depends on random seed)")

func test_path_endpoint_detection():
	print("\n--- Test: Path Endpoint Detection ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 99999
	
	# Generate multiple chunks
	var endpoints_found = 0
	for x in range(-3, 4):
		for z in range(-3, 4):
			var chunk_pos = Vector2i(x, z)
			var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
			
			for segment in segments:
				if segment.is_endpoint:
					endpoints_found += 1
	
	if endpoints_found > 0:
		print("PASS: Found ", endpoints_found, " path endpoints")
	else:
		print("INFO: No endpoints found (depends on random seed)")

func test_starting_chunk():
	print("\n--- Test: Starting Chunk (0,0) Has Path ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	var chunk_pos = Vector2i(0, 0)
	
	var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	if segments.size() > 0:
		var has_main_path = false
		for segment in segments:
			if segment.path_type == PathSystem.PathType.MAIN_PATH:
				has_main_path = true
				break
		
		if has_main_path:
			print("PASS: Starting chunk has main path")
		else:
			print("FAIL: Starting chunk missing main path")
	else:
		print("FAIL: Starting chunk has no paths")
	
	PathSystem.clear_all_paths()

func test_seed_consistency():
	print("\n--- Test: Seed Consistency ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	var chunk_pos = Vector2i(5, 3)
	
	var segments1 = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	PathSystem.clear_all_paths()
	var segments2 = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	if segments1.size() == segments2.size():
		print("PASS: Same number of segments with same seed: ", segments1.size())
	else:
		print("FAIL: Different number of segments: ", segments1.size(), " vs ", segments2.size())
	
	PathSystem.clear_all_paths()
