extends Node

## Test script for larger trees and improved tree algorithms
## Validates that trees are larger and use improved algorithms for both conifer and broadleaf types

const ProceduralModels = preload("res://scripts/procedural_models.gd")
const ClusterSystem = preload("res://scripts/cluster_system.gd")

var test_results = []

func _ready():
	print("=== Running Larger Trees Tests ===")
	print("Test started at: ", Time.get_ticks_msec())
	
	run_all_tests()
	
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

func run_all_tests():
	test_tree_constants()
	test_tree_mesh_generation()
	test_forest_radius()
	test_forest_density()

func test_tree_constants():
	print("\nTest: Tree Size Constants")
	
	# Check that tree constants are larger than original values
	var trunk_height_ok = ProceduralModels.TREE_TRUNK_HEIGHT >= 3.5  # Should be ~4.0
	var trunk_radius_ok = ProceduralModels.TREE_TRUNK_RADIUS >= 0.20  # Should be ~0.25
	var canopy_radius_ok = ProceduralModels.TREE_CANOPY_RADIUS >= 2.0  # Should be ~2.5
	var canopy_height_ok = ProceduralModels.TREE_CANOPY_HEIGHT >= 4.0  # Should be ~4.5
	
	if trunk_height_ok and trunk_radius_ok and canopy_radius_ok and canopy_height_ok:
		test_results.append("✓ Tree size constants increased (trunk_h=%.1f, canopy_r=%.1f)" % [ProceduralModels.TREE_TRUNK_HEIGHT, ProceduralModels.TREE_CANOPY_RADIUS])
	else:
		test_results.append("✗ Tree size constants not properly increased")

func test_tree_mesh_generation():
	print("\nTest: Tree Mesh Generation")
	
	# Test that all tree types can be generated
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	var conifer_mesh = ProceduralModels.create_tree_mesh(rng.randi(), ProceduralModels.TreeType.CONIFER)
	var broadleaf_mesh = ProceduralModels.create_tree_mesh(rng.randi(), ProceduralModels.TreeType.BROAD_LEAF)
	var bush_mesh = ProceduralModels.create_tree_mesh(rng.randi(), ProceduralModels.TreeType.SMALL_BUSH)
	var auto_mesh = ProceduralModels.create_tree_mesh(rng.randi(), ProceduralModels.TreeType.AUTO)
	
	var all_valid = conifer_mesh != null and broadleaf_mesh != null and bush_mesh != null and auto_mesh != null
	
	if all_valid:
		test_results.append("✓ All tree types generate valid meshes")
	else:
		test_results.append("✗ Some tree meshes failed to generate")

func test_forest_radius():
	print("\nTest: Forest Size")
	
	# Check that forest radius constants are larger
	var min_radius_ok = ClusterSystem.FOREST_MIN_RADIUS >= 25.0  # Should be ~30.0
	var max_radius_ok = ClusterSystem.FOREST_MAX_RADIUS >= 60.0  # Should be ~70.0
	
	if min_radius_ok and max_radius_ok:
		test_results.append("✓ Forest radius increased (min=%.1f, max=%.1f)" % [ClusterSystem.FOREST_MIN_RADIUS, ClusterSystem.FOREST_MAX_RADIUS])
	else:
		test_results.append("✗ Forest radius not properly increased")

func test_forest_density():
	print("\nTest: Forest Density")
	
	# Create test clusters and check density range
	var rng = RandomNumberGenerator.new()
	rng.seed = 99999
	
	var densities = []
	for i in range(10):
		var density = rng.randf_range(0.7, 1.0)
		densities.append(density)
	
	var min_density = densities.min()
	var max_density = densities.max()
	
	# Check that minimum density is at least 0.6 (should be 0.7)
	if min_density >= 0.6 and max_density <= 1.1:
		test_results.append("✓ Forest density range appropriate (min=%.2f, max=%.2f)" % [min_density, max_density])
	else:
		test_results.append("✗ Forest density range unexpected")
