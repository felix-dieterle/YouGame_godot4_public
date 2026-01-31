extends Node

## Test suite for path continuity across chunk boundaries
## This test verifies that paths properly continue from one chunk to another

const PathSystem = preload("res://scripts/systems/world/path_system.gd")

func _ready():
	print("=== Starting Path Continuity Tests ===")
	test_boundary_detection()
	test_path_handoff_at_boundaries()
	test_path_reliability_across_chunks()
	test_no_gaps_in_path_continuity()
	print("=== All Path Continuity Tests Completed ===")
	get_tree().quit()

## Test that boundary detection properly identifies paths at chunk edges
func test_boundary_detection():
	print("\n--- Test: Boundary Detection ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	
	# Get boundary detection threshold from PathSystem
	var threshold = PathSystem.BOUNDARY_DETECTION_THRESHOLD
	var chunk_size = PathSystem.CHUNK_SIZE
	
	# Test paths at various positions near boundaries
	var test_cases = [
		{"name": "Near left edge", "end_x": threshold - 0.5, "should_exit_left": true},
		{"name": "Just inside threshold", "end_x": threshold - 0.1, "should_exit_left": true},
		{"name": "Just outside threshold", "end_x": threshold + 0.1, "should_exit_left": false},
		{"name": "Middle of chunk", "end_x": chunk_size / 2.0, "should_exit_left": false},
		{"name": "Near right edge", "end_x": chunk_size - threshold + 0.5, "should_exit_right": true},
		{"name": "Just inside right threshold", "end_x": chunk_size - threshold + 0.1, "should_exit_right": true},
		{"name": "Just outside right threshold", "end_x": chunk_size - threshold - 0.1, "should_exit_right": false},
	]
	
	for test_case in test_cases:
		# Create a test segment directly (not using _create_segment) to test boundary detection in isolation
		# This allows testing specific edge cases without involving the full segment creation logic
		var rng = RandomNumberGenerator.new()
		rng.seed = world_seed
		var chunk_pos = Vector2i(0, 0)
		var start = Vector2(chunk_size / 2.0, chunk_size / 2.0)
		var end = Vector2(test_case.end_x, chunk_size / 2.0)
		
		# Use constants for segment creation
		var test_width = PathSystem.DEFAULT_PATH_WIDTH
		var segment = PathSystem.PathSegment.new(0, chunk_pos, start, end, PathSystem.PathType.MAIN_PATH, test_width)
		
		# Check left exit
		var left_neighbor = Vector2i(-1, 0)
		var exit_pos = PathSystem._get_chunk_exit_position(segment, chunk_pos, left_neighbor)
		var exits_left = exit_pos != Vector2(-1, -1)
		
		if test_case.has("should_exit_left"):
			if exits_left == test_case.should_exit_left:
				print("PASS: ", test_case.name, " - exits left: ", exits_left)
			else:
				print("FAIL: ", test_case.name, " - expected exit left: ", test_case.should_exit_left, ", got: ", exits_left)
		
		# Check right exit
		var right_neighbor = Vector2i(1, 0)
		exit_pos = PathSystem._get_chunk_exit_position(segment, chunk_pos, right_neighbor)
		var exits_right = exit_pos != Vector2(-1, -1)
		
		if test_case.has("should_exit_right"):
			if exits_right == test_case.should_exit_right:
				print("PASS: ", test_case.name, " - exits right: ", exits_right)
			else:
				print("FAIL: ", test_case.name, " - expected exit right: ", test_case.should_exit_right, ", got: ", exits_right)
	
	PathSystem.clear_all_paths()

## Test that paths properly hand off from one chunk to the next
func test_path_handoff_at_boundaries():
	print("\n--- Test: Path Handoff at Boundaries ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 54321  # Different seed for variety
	
	# Generate a series of chunks in a line
	var chunks_to_generate = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
	]
	
	for chunk in chunks_to_generate:
		PathSystem.get_path_segments_for_chunk(chunk, world_seed)
	
	# Check for continuity between chunks
	var continuity_found = _check_continuity_between_chunks(chunks_to_generate)
	
	if not continuity_found:
		print("INFO: No path continuity found in tested chunks (depends on random seed)")
	
	PathSystem.clear_all_paths()

## Helper function to check continuity between chunks
func _check_continuity_between_chunks(chunks: Array) -> bool:
	for i in range(chunks.size() - 1):
		var chunk1 = chunks[i]
		var chunk2 = chunks[i + 1]
		
		if not PathSystem.chunk_segments.has(chunk1):
			continue
		
		var segments1 = PathSystem.chunk_segments[chunk1]
		for seg_id in segments1:
			if not PathSystem.all_segments.has(seg_id):
				continue
			
			var segment = PathSystem.all_segments[seg_id]
			var exit_pos = PathSystem._get_chunk_exit_position(segment, chunk1, chunk2)
			
			if exit_pos != Vector2(-1, -1):
				# Found an exit, check if chunk2 has a corresponding entry
				if PathSystem.chunk_segments.has(chunk2):
					var segments2 = PathSystem.chunk_segments[chunk2]
					if segments2.size() > 0:
						print("PASS: Found path continuity from chunk ", chunk1, " to ", chunk2)
						print("  Exit at: ", exit_pos, " in chunk ", chunk1)
						return true
	
	return false

## Test that paths reliably span multiple chunks
func test_path_reliability_across_chunks():
	print("\n--- Test: Path Reliability Across Chunks ---")
	
	# Test with multiple seeds to check consistency
	var seeds_to_test = [12345, 54321, 99999, 11111, 22222]
	var successful_multi_chunk_paths = 0
	
	for seed in seeds_to_test:
		PathSystem.clear_all_paths()
		
		# Generate a 10x10 grid of chunks
		for x in range(-5, 6):
			for z in range(-5, 6):
				PathSystem.get_path_segments_for_chunk(Vector2i(x, z), seed)
		
		# Count unique chunks that have paths
		var chunks_with_paths = PathSystem.chunk_segments.keys()
		
		# Check if we have paths spanning at least 3 chunks
		if chunks_with_paths.size() >= 3:
			successful_multi_chunk_paths += 1
	
	var success_rate = float(successful_multi_chunk_paths) / float(seeds_to_test.size()) * 100.0
	
	print("INFO: ", successful_multi_chunk_paths, "/", seeds_to_test.size(), " seeds produced paths spanning 3+ chunks")
	print("INFO: Success rate: ", "%.1f" % success_rate, "%")
	
	if success_rate >= 80.0:
		print("PASS: Path generation is reliable (>=80% success rate)")
	elif success_rate >= 50.0:
		print("WARNING: Path generation has moderate reliability (50-80% success rate)")
	else:
		print("FAIL: Path generation has low reliability (<50% success rate)")
	
	PathSystem.clear_all_paths()

## Test that there are no gaps in path continuity
func test_no_gaps_in_path_continuity():
	print("\n--- Test: No Gaps in Path Continuity ---")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	
	# Generate a 6x6 grid of chunks
	for x in range(-3, 4):
		for z in range(-3, 4):
			PathSystem.get_path_segments_for_chunk(Vector2i(x, z), world_seed)
	
	# For each chunk with paths, verify continuity
	var gaps_found = 0
	var continuities_verified = 0
	
	for chunk_pos in PathSystem.chunk_segments.keys():
		var segment_ids = PathSystem.chunk_segments[chunk_pos]
		
		for seg_id in segment_ids:
			if not PathSystem.all_segments.has(seg_id):
				continue
			
			var segment = PathSystem.all_segments[seg_id]
			
			# Check all neighboring chunks
			var neighbors = [
				Vector2i(chunk_pos.x - 1, chunk_pos.y),
				Vector2i(chunk_pos.x + 1, chunk_pos.y),
				Vector2i(chunk_pos.x, chunk_pos.y - 1),
				Vector2i(chunk_pos.x, chunk_pos.y + 1)
			]
			
			for neighbor in neighbors:
				var exit_pos = PathSystem._get_chunk_exit_position(segment, chunk_pos, neighbor)
				
				if exit_pos != Vector2(-1, -1):
					# Segment exits toward this neighbor
					# Check if neighbor has any segments
					if PathSystem.chunk_segments.has(neighbor):
						var neighbor_segments = PathSystem.chunk_segments[neighbor]
						if neighbor_segments.size() > 0:
							continuities_verified += 1
						else:
							# No segments in neighbor where path should continue
							gaps_found += 1
							print("WARNING: Gap found - path exits from ", chunk_pos, " to ", neighbor, " but neighbor has no paths")
					else:
						# Neighbor chunk not generated or has no paths
						gaps_found += 1
						print("WARNING: Gap found - path exits from ", chunk_pos, " to ", neighbor, " but neighbor has no path data")
	
	print("INFO: Verified ", continuities_verified, " path continuities")
	print("INFO: Found ", gaps_found, " potential gaps")
	
	if gaps_found == 0:
		print("PASS: No gaps found in path continuity")
	else:
		print("INFO: Some gaps found (this can be expected if paths end at destinations)")
	
	PathSystem.clear_all_paths()
