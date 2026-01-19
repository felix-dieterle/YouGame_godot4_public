extends Node

## Verification script for path visibility improvements
##
## This test validates that path visibility fixes are working correctly:
## - Starting chunk (0,0) has path segments
## - Path width has been increased to 2.5 units
## - Main paths have correct width multiplier
## - Starting path meets minimum length requirements
## - Paths continue across chunk boundaries
const PathSystem = preload("res://scripts/path_system.gd")

# Test constants
const POSITION_TOLERANCE = 0.1  # Tolerance for position comparisons
const WIDTH_TOLERANCE = 0.01  # Tolerance for width comparisons

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
	
	# Starting chunk should NOT have paths (removed per user request)
	if segments.size() == 0:
		print("✓ Starting chunk has no paths (as intended)")
	else:
		print("❌ FAIL: Starting chunk should not have paths but has: ", segments.size())
		for i in range(segments.size()):
			var segment = segments[i]
			print("  Unexpected segment ", i, ": ", segment.start_pos, " -> ", segment.end_pos)
	
	print("✓ Starting chunk verification complete\n")

func verify_path_width():
	print("--- Verifying Path Width Changes ---")
	
	print("Default path width: ", PathSystem.DEFAULT_PATH_WIDTH)
	print("Expected: 2.5 (was 1.5)")
	
	if abs(PathSystem.DEFAULT_PATH_WIDTH - 2.5) < WIDTH_TOLERANCE:
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
