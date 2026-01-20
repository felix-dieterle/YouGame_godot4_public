extends Node

# Test suite for woodpecker ambient sound system in dense forests
const CHUNK = preload("res://scripts/chunk.gd")
const ClusterSystem = preload("res://scripts/cluster_system.gd")

func _ready():
	print("=== Starting Woodpecker Sound Tests ===")
	test_woodpecker_sound_in_forest()
	test_no_woodpecker_in_open_area()
	print("=== All Woodpecker Sound Tests Completed ===")
	get_tree().quit()

func test_woodpecker_sound_in_forest():
	print("\n--- Test: Woodpecker Sound in Dense Forest ---")
	
	# Create a world seed that generates forests
	var seed_value = 54321
	
	# Test multiple chunks to find one with a forest
	var found_forest_with_sound = false
	var test_count = 50
	
	for i in range(test_count):
		for j in range(test_count):
			var chunk = CHUNK.new(i, j, seed_value)
			chunk.generate()
			
			# Check if this chunk has forest clusters
			var chunk_pos = Vector2i(i, j)
			var forest_clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, seed_value)
			
			# Calculate forest density
			var max_forest_density = 0.0
			for cluster in forest_clusters:
				if cluster.type == ClusterSystem.ClusterType.FOREST:
					var chunk_center = Vector2(i * CHUNK.CHUNK_SIZE + CHUNK.CHUNK_SIZE / 2.0, j * CHUNK.CHUNK_SIZE + CHUNK.CHUNK_SIZE / 2.0)
					var influence = ClusterSystem.get_cluster_influence_at_pos(chunk_center, cluster)
					max_forest_density = max(max_forest_density, influence * cluster.density)
			
			# If forest density is high enough, check for ambient sound player
			if max_forest_density > 0.5:
				if chunk.ambient_sound_player != null:
					print("  Found dense forest at chunk (%d, %d) with ambient sound (density: %.2f)" % [i, j, max_forest_density])
					print("  - Sound player position: %s" % str(chunk.ambient_sound_player.position))
					print("  - Woodpecker interval: %.2fs" % chunk.woodpecker_interval)
					found_forest_with_sound = true
					chunk.free()
					break
			
			chunk.free()
		
		if found_forest_with_sound:
			break
	
	if found_forest_with_sound:
		print("PASS: Dense forest chunks have woodpecker ambient sounds")
	else:
		print("FAIL: No dense forest chunks with ambient sounds found (may need more chunks to test)")

func test_no_woodpecker_in_open_area():
	print("\n--- Test: No Woodpecker Sound in Open Areas ---")
	
	# Create chunks without forests
	var seed_value = 11111
	var chunk = CHUNK.new(100, 100, seed_value)  # Far from origin, less likely to have forest
	chunk.generate()
	
	# Check if this chunk has low forest density
	var chunk_pos = Vector2i(100, 100)
	var forest_clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, seed_value)
	
	var max_forest_density = 0.0
	for cluster in forest_clusters:
		if cluster.type == ClusterSystem.ClusterType.FOREST:
			var chunk_center = Vector2(100 * CHUNK.CHUNK_SIZE + CHUNK.CHUNK_SIZE / 2.0, 100 * CHUNK.CHUNK_SIZE + CHUNK.CHUNK_SIZE / 2.0)
			var influence = ClusterSystem.get_cluster_influence_at_pos(chunk_center, cluster)
			max_forest_density = max(max_forest_density, influence * cluster.density)
	
	print("  Chunk (100, 100) forest density: %.2f" % max_forest_density)
	
	# If forest density is low, should not have ambient sound
	if max_forest_density <= 0.5:
		if chunk.ambient_sound_player == null:
			print("PASS: Open area chunks do not have woodpecker sounds")
		else:
			print("FAIL: Open area chunk has ambient sound when it shouldn't")
	else:
		print("INFO: Chunk has high forest density, skipping test")
	
	chunk.free()
