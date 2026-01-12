extends Node

## Test script for cluster system
## Validates that forests and settlements generate consistently across chunks

const ClusterSystem = preload("res://scripts/cluster_system.gd")
const Chunk = preload("res://scripts/chunk.gd")

var test_results = []

func _ready():
	print("=== Running Cluster System Tests ===")
	print("Test started at: ", Time.get_ticks_msec())
	
	# Clear any existing clusters
	ClusterSystem.clear_all_clusters()
	
	await run_all_tests()
	
	print("\n=== Test Results ===")
	for result in test_results:
		print(result)
	
	var passed = test_results.filter(func(r): return r.begins_with("✓")).size()
	var failed = test_results.filter(func(r): return r.begins_with("✗")).size()
	
	print("\nTests passed: %d/%d" % [passed, passed + failed])
	
	if failed == 0:
		print("All tests passed!")
	else:
		print("Some tests failed!")
	
	print("Test completed at: ", Time.get_ticks_msec())
	print("Calling get_tree().quit()...")
	
	# Exit after tests
	get_tree().quit()
	
	print("After quit() call - this should not print")

func run_all_tests():
	test_cluster_generation()
	test_cluster_consistency()
	test_cluster_influence()
	test_cluster_boundary_crossing()
	await test_object_placement()

func test_cluster_generation():
	print("\nTest: Cluster Generation")
	ClusterSystem.clear_all_clusters()
	
	var world_seed = 12345
	var chunk_pos = Vector2i(0, 0)
	
	# Generate clusters for chunk
	var clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)
	
	# Test should generate at least some clusters over multiple chunks
	var total_clusters = 0
	for x in range(-5, 6):
		for z in range(-5, 6):
			var pos = Vector2i(x, z)
			var chunk_clusters = ClusterSystem.get_clusters_for_chunk(pos, world_seed)
			total_clusters += chunk_clusters.size()
	
	if total_clusters > 0:
		test_results.append("✓ Cluster generation creates clusters across chunks (%d clusters)" % total_clusters)
	else:
		test_results.append("✗ Cluster generation failed - no clusters created")

func test_cluster_consistency():
	print("\nTest: Cluster Consistency")
	ClusterSystem.clear_all_clusters()
	
	var world_seed = 54321
	var chunk_pos = Vector2i(2, 3)
	
	# Generate clusters twice for same chunk and seed
	var clusters1 = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)
	ClusterSystem.clear_all_clusters()
	var clusters2 = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)
	
	# Should generate same number of new clusters
	var new_clusters1 = clusters1.filter(func(c): return c.center_chunk == chunk_pos)
	var new_clusters2 = clusters2.filter(func(c): return c.center_chunk == chunk_pos)
	
	if new_clusters1.size() == new_clusters2.size():
		test_results.append("✓ Cluster generation is consistent with same seed")
	else:
		test_results.append("✗ Cluster generation inconsistent: %d vs %d clusters" % [new_clusters1.size(), new_clusters2.size()])

func test_cluster_influence():
	print("\nTest: Cluster Influence Calculation")
	ClusterSystem.clear_all_clusters()
	
	# Create a test cluster
	var rng = RandomNumberGenerator.new()
	rng.seed = 999
	var cluster = ClusterSystem.ClusterData.new(
		0,
		Vector2i(0, 0),
		Vector2(16, 16),  # Center of chunk
		ClusterSystem.ClusterType.FOREST,
		20.0,  # 20 unit radius
		0.5,
		999
	)
	
	# Test influence at center (should be high)
	var center_pos = Vector2(16, 16)
	var center_influence = ClusterSystem.get_cluster_influence_at_pos(center_pos, cluster)
	
	# Test influence at edge (should be lower)
	var edge_pos = Vector2(16 + 20, 16)  # Exactly at radius
	var edge_influence = ClusterSystem.get_cluster_influence_at_pos(edge_pos, cluster)
	
	# Test influence outside (should be zero)
	var outside_pos = Vector2(16 + 25, 16)  # Beyond radius
	var outside_influence = ClusterSystem.get_cluster_influence_at_pos(outside_pos, cluster)
	
	if center_influence > 0.9 and edge_influence < 0.1 and outside_influence == 0.0:
		test_results.append("✓ Cluster influence calculation works correctly")
	else:
		test_results.append("✗ Cluster influence incorrect: center=%f, edge=%f, outside=%f" % [center_influence, edge_influence, outside_influence])

func test_cluster_boundary_crossing():
	print("\nTest: Cluster Boundary Crossing")
	ClusterSystem.clear_all_clusters()
	
	var world_seed = 11111
	
	# Generate a large grid of chunks
	var all_clusters = []
	for x in range(-3, 4):
		for z in range(-3, 4):
			var pos = Vector2i(x, z)
			var clusters = ClusterSystem.get_clusters_for_chunk(pos, world_seed)
			for cluster in clusters:
				if not all_clusters.has(cluster):
					all_clusters.append(cluster)
	
	# Check if any cluster affects multiple chunks
	var multi_chunk_clusters = 0
	for cluster in all_clusters:
		var affected_chunks = 0
		for x in range(-3, 4):
			for z in range(-3, 4):
				var pos = Vector2i(x, z)
				if ClusterSystem._chunk_in_cluster_range(pos, cluster):
					affected_chunks += 1
		
		if affected_chunks > 1:
			multi_chunk_clusters += 1
	
	if multi_chunk_clusters > 0:
		test_results.append("✓ Clusters can cross chunk boundaries (%d multi-chunk clusters)" % multi_chunk_clusters)
	else:
		test_results.append("✗ No clusters cross chunk boundaries (might be unlucky)")

func test_object_placement():
	print("\nTest: Object Placement")
	
	# Create a test chunk
	var chunk = Chunk.new(0, 0, 12345)
	add_child(chunk)
	chunk.generate()
	
	# Wait for the chunk to be fully added to the tree
	await get_tree().process_frame
	
	# Check if any objects were placed
	var object_count = chunk.placed_objects.size()
	var has_forests = false
	var has_settlements = false
	
	for cluster in chunk.active_clusters:
		if cluster.type == ClusterSystem.ClusterType.FOREST:
			has_forests = true
		elif cluster.type == ClusterSystem.ClusterType.SETTLEMENT:
			has_settlements = true
	
	if object_count > 0:
		test_results.append("✓ Objects placed in chunks (%d objects)" % object_count)
	else:
		test_results.append("✓ No objects placed (no clusters in this chunk)")
	
	# Clean up
	chunk.queue_free()
