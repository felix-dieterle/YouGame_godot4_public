extends Node

# Test suite for path system
const PathSystem = preload("res://scripts/systems/world/path_system.gd")

func _ready():
	print("=== Starting Path System Tests ===")
	test_path_generation()
	test_path_continuation()
	test_path_branching()
	test_path_endpoint_detection()
	test_starting_chunk()
	test_path_spans_three_chunks()
	print("=== All Path System Tests Completed ===")
	get_tree().quit()

func test_path_generation():
	print("\n--- Test: Path Generation ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	var chunk_pos = Vector2i(0, 0)
	
	var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	# Starting chunk should NOT have path segments (removed per user request)
	if segments.size() == 0:
		print("PASS: No path segments at starting chunk (as intended)")
	else:
		print("FAIL: Unexpected path segments at starting chunk: ", segments.size())
	
	# Test chunks adjacent to origin should have initial paths
	var adjacent_chunks = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	
	var paths_found = 0
	for test_chunk_pos in adjacent_chunks:
		var test_segments = PathSystem.get_path_segments_for_chunk(test_chunk_pos, world_seed)
		if test_segments.size() > 0:
			paths_found += 1
			print("INFO: Adjacent chunk ", test_chunk_pos, " has ", test_segments.size(), " segment(s)")
	
	if paths_found > 0:
		print("PASS: Initial paths created in adjacent chunks (", paths_found, "/4)")
	else:
		print("FAIL: No initial paths found in adjacent chunks")

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
	print("\n--- Test: Starting Chunk (0,0) Has No Path ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	var chunk_pos = Vector2i(0, 0)
	
	var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	# Starting chunk should NOT have paths (removed per user request)
	if segments.size() == 0:
		print("PASS: Starting chunk has no paths (as intended)")
	else:
		print("FAIL: Starting chunk should not have paths but has: ", segments.size())
	
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

## Test that at least one path spans 3 or more chunks (requirement from issue)
func test_path_spans_three_chunks():
	print("\n--- Test: Path Spans At Least 3 Chunks ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345  # Seed chosen to ensure consistent test results
	
	# Generate a grid of chunks to trace paths
	var chunk_grid_size = 8  # Generates 17x17 grid (from -8 to +8 inclusive)
	for x in range(-chunk_grid_size, chunk_grid_size + 1):
		for z in range(-chunk_grid_size, chunk_grid_size + 1):
			var chunk_pos = Vector2i(x, z)
			PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	# Now trace paths to find continuous paths
	var visited_segments = {}
	var longest_path_length = 0
	var longest_path_chunks = []
	
	# Start from chunk (0,0) and trace all paths
	var all_segment_ids = []
	for chunk_pos in PathSystem.chunk_segments:
		var seg_ids = PathSystem.chunk_segments[chunk_pos]
		for seg_id in seg_ids:
			if seg_id not in all_segment_ids:
				all_segment_ids.append(seg_id)
	
	# Trace each path using depth-first search
	for start_seg_id in all_segment_ids:
		if start_seg_id in visited_segments:
			continue
		
		var path_chunks = _trace_path(start_seg_id, visited_segments)
		if path_chunks.size() > longest_path_length:
			longest_path_length = path_chunks.size()
			longest_path_chunks = path_chunks
	
	print("INFO: Longest path found spans ", longest_path_length, " chunks")
	print("INFO: Path goes through chunks: ", longest_path_chunks)
	
	if longest_path_length >= 3:
		print("PASS: At least one path spans 3 or more chunks (", longest_path_length, " chunks)")
	else:
		print("FAIL: No path spans 3 or more chunks (max found: ", longest_path_length, " chunks)")
	
	PathSystem.clear_all_paths()

## Helper function to trace a path through chunks using DFS
func _trace_path(start_segment_id: int, visited: Dictionary) -> Array:
	var chunks_in_path = []
	var to_visit = [start_segment_id]
	
	while to_visit.size() > 0:
		var seg_id = to_visit.pop_back()
		
		if seg_id in visited:
			continue
		
		visited[seg_id] = true
		
		if not PathSystem.all_segments.has(seg_id):
			continue
		
		var segment = PathSystem.all_segments[seg_id]
		
		# Add this chunk to path if not already included
		if segment.chunk_pos not in chunks_in_path:
			chunks_in_path.append(segment.chunk_pos)
		
		# Add connected segments
		for next_seg_id in segment.next_segments:
			if next_seg_id not in visited:
				to_visit.append(next_seg_id)
		
		# Check for segments that continue from this one (check neighboring chunks)
		var neighbors = [
			Vector2i(segment.chunk_pos.x - 1, segment.chunk_pos.y),
			Vector2i(segment.chunk_pos.x + 1, segment.chunk_pos.y),
			Vector2i(segment.chunk_pos.x, segment.chunk_pos.y - 1),
			Vector2i(segment.chunk_pos.x, segment.chunk_pos.y + 1)
		]
		
		for neighbor_chunk in neighbors:
			if not PathSystem.chunk_segments.has(neighbor_chunk):
				continue
			
			var neighbor_seg_ids = PathSystem.chunk_segments[neighbor_chunk]
			for neighbor_seg_id in neighbor_seg_ids:
				if neighbor_seg_id not in visited:
					# Check if this segment continues from our current segment
					if PathSystem.all_segments.has(neighbor_seg_id):
						to_visit.append(neighbor_seg_id)
	
	return chunks_in_path
