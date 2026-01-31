extends Node

## Manual verification script for path generation
## This script demonstrates that paths are now being generated correctly

const PathSystem = preload("res://scripts/systems/world/path_system.gd")

func _ready():
	print("=== Path Generation Verification ===\n")
	
	PathSystem.clear_all_paths()
	var world_seed = 12345
	
	print("Step 1: Generate starting chunk (0,0)")
	var chunk_00 = PathSystem.get_path_segments_for_chunk(Vector2i(0, 0), world_seed)
	print("  Chunk (0,0) has ", chunk_00.size(), " paths (should be 0)")
	
	print("\nStep 2: Generate adjacent chunks")
	var adjacent_chunks = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	
	for chunk_pos in adjacent_chunks:
		var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
		print("  Chunk ", chunk_pos, " has ", segments.size(), " paths")
		
		for segment in segments:
			print("    - Segment ", segment.segment_id, ": ", segment.path_type)
			print("      Start: ", segment.start_pos, " End: ", segment.end_pos)
	
	print("\nStep 3: Generate second ring of chunks")
	var second_ring = [
		Vector2i(2, 0),
		Vector2i(1, 1),
		Vector2i(0, 2),
		Vector2i(-1, 1),
		Vector2i(-2, 0),
		Vector2i(-1, -1),
		Vector2i(0, -2),
		Vector2i(1, -1)
	]
	
	var paths_in_second_ring = 0
	for chunk_pos in second_ring:
		var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
		if segments.size() > 0:
			paths_in_second_ring += 1
			print("  Chunk ", chunk_pos, " has ", segments.size(), " paths")
	
	print("\nSummary:")
	print("  Total chunks with paths: ", PathSystem.chunk_segments.size())
	print("  Total path segments: ", PathSystem.get_total_segments())
	print("  Second ring chunks with paths: ", paths_in_second_ring, "/8")
	
	if PathSystem.get_total_segments() > 0:
		print("\n✓ SUCCESS: Path generation is working!")
	else:
		print("\n✗ FAIL: No paths generated")
	
	print("\n=== Verification Complete ===")
	get_tree().quit()
