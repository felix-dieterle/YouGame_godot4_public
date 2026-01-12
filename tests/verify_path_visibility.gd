extends Node

# Verification script for path visibility improvements
const PathSystem = preload("res://scripts/path_system.gd")

func _ready():
	print("=== Path Visibility Verification ===\n")
	
	verify_starting_chunk_path()
	verify_path_width()
	verify_path_continuation()
	
	print("\n=== Verification Complete ===")
	get_tree().quit()

func verify_starting_chunk_path():
	print("--- Verifying Starting Chunk Path ---")
	PathSystem.clear_all_paths()
	
	var world_seed = 12345
	var chunk_pos = Vector2i(0, 0)
	var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
	
	print("Starting chunk (0,0) has ", segments.size(), " path segment(s)")
	
	if segments.size() == 0:
		print("❌ FAIL: No paths in starting chunk!")
		return
	
	for i in range(segments.size()):
		var segment = segments[i]
		print("  Segment ", i, ":")
		
		# Safely get path type name
		var type_name = "UNKNOWN"
		match segment.path_type:
			PathSystem.PathType.MAIN_PATH:
				type_name = "MAIN_PATH"
			PathSystem.PathType.BRANCH:
				type_name = "BRANCH"
			PathSystem.PathType.FOREST_PATH:
				type_name = "FOREST_PATH"
			PathSystem.PathType.VILLAGE_PATH:
				type_name = "VILLAGE_PATH"
		
		print("    Type: ", type_name)
		print("    Width: ", segment.width, " (default: ", PathSystem.DEFAULT_PATH_WIDTH, ")")
		print("    Start: ", segment.start_pos)
		print("    End: ", segment.end_pos)
		
		var length = segment.start_pos.distance_to(segment.end_pos)
		print("    Length: ", length)
		
		# Verify main path properties
		if segment.path_type == PathSystem.PathType.MAIN_PATH:
			var expected_width = PathSystem.DEFAULT_PATH_WIDTH * PathSystem.MAIN_PATH_WIDTH_MULTIPLIER
			if abs(segment.width - expected_width) < 0.01:
				print("    ✓ Main path has correct width (", expected_width, ")")
			else:
				print("    ❌ Main path width incorrect: ", segment.width, " expected: ", expected_width)
			
			# Check if path is long enough to be visible
			if length >= PathSystem.MAX_SEGMENT_LENGTH * PathSystem.MIN_STARTING_PATH_RATIO:
				print("    ✓ Path is long enough to be visible (>= ", PathSystem.MAX_SEGMENT_LENGTH * PathSystem.MIN_STARTING_PATH_RATIO, ")")
			else:
				print("    ⚠ Path might be too short: ", length)
	
	print("✓ Starting chunk verification complete\n")

func verify_path_width():
	print("--- Verifying Path Width Changes ---")
	
	print("Default path width: ", PathSystem.DEFAULT_PATH_WIDTH)
	print("Expected: 2.5 (was 1.5)")
	
	if abs(PathSystem.DEFAULT_PATH_WIDTH - 2.5) < 0.01:
		print("✓ Path width increased correctly\n")
	else:
		print("❌ Path width not set correctly: ", PathSystem.DEFAULT_PATH_WIDTH, "\n")

func verify_path_continuation():
	print("--- Verifying Path Continuation ---")
	PathSystem.clear_all_paths()
	
	var world_seed = 12345
	
	# Generate starting chunk
	var start_chunk = Vector2i(0, 0)
	var start_segments = PathSystem.get_path_segments_for_chunk(start_chunk, world_seed)
	
	print("Starting chunk has ", start_segments.size(), " segment(s)")
	
	# Generate neighboring chunks to see if paths continue
	var neighbors = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(0, -1)
	]
	
	var total_neighbor_segments = 0
	for neighbor in neighbors:
		var neighbor_segments = PathSystem.get_path_segments_for_chunk(neighbor, world_seed)
		if neighbor_segments.size() > 0:
			print("  Neighbor ", neighbor, " has ", neighbor_segments.size(), " segment(s)")
			total_neighbor_segments += neighbor_segments.size()
	
	if total_neighbor_segments > 0:
		print("✓ Paths continue to neighboring chunks (", total_neighbor_segments, " total segments)\n")
	else:
		print("⚠ No path continuation found (may be due to path direction)\n")
	
	PathSystem.clear_all_paths()
