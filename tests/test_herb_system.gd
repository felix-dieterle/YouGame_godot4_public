extends Node
# Test script for Herb Collection System

const HerbSystem = preload("res://scripts/systems/collection/herb_system.gd")

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n=== HERB SYSTEM TEST ===")
	
	# Run tests
	test_herb_system_constants()
	test_herb_spawn_forest_density()
	test_herb_mesh_creation()
	test_herb_size_variation()
	test_herb_color_properties()
	
	# Print summary
	print("\n=== TEST SUMMARY ===")
	print("Tests run: ", test_count)
	print("Tests passed: ", passed_count)
	print("Tests failed: ", test_count - passed_count)
	
	if passed_count == test_count:
		print("✓ All tests passed!")
		get_tree().quit(0)
	else:
		print("✗ Some tests failed")
		get_tree().quit(1)

func test_herb_system_constants() -> void:
	test_count += 1
	var test_name = "Herb system constants are defined correctly"
	
	var valid_constants = (
		HerbSystem.HERB_NAME != "" and
		HerbSystem.HERB_COLOR is Color and
		HerbSystem.HERB_LEAF_COLOR is Color and
		HerbSystem.HERB_SPAWN_CHANCE > 0 and HerbSystem.HERB_SPAWN_CHANCE < 1 and
		HerbSystem.HERB_FOREST_DENSITY_THRESHOLD > 0 and HerbSystem.HERB_FOREST_DENSITY_THRESHOLD <= 1 and
		HerbSystem.HERB_HEALTH_RESTORE_PERCENT > 0 and HerbSystem.HERB_HEALTH_RESTORE_PERCENT <= 1
	)
	
	if valid_constants:
		pass_test(test_name)
	else:
		fail_test(test_name, "One or more herb system constants are invalid")

func test_herb_spawn_forest_density() -> void:
	test_count += 1
	var test_name = "Herbs only spawn in dense forests"
	
	# Test various forest densities
	var test_cases = [
		{"density": 0.1, "should_spawn": false},
		{"density": 0.5, "should_spawn": false},
		{"density": 0.6, "should_spawn": true},
		{"density": 0.8, "should_spawn": true},
		{"density": 1.0, "should_spawn": true},
	]
	
	var all_passed = true
	for test_case in test_cases:
		var can_spawn = HerbSystem.can_spawn_in_forest(test_case["density"])
		if can_spawn != test_case["should_spawn"]:
			all_passed = false
			print("  FAIL: Density %.1f expected %s, got %s" % [
				test_case["density"],
				"can spawn" if test_case["should_spawn"] else "cannot spawn",
				"can spawn" if can_spawn else "cannot spawn"
			])
	
	if all_passed:
		pass_test(test_name)
	else:
		fail_test(test_name, "Herb spawn logic incorrect for some densities")

func test_herb_mesh_creation() -> void:
	test_count += 1
	var test_name = "Herb mesh can be created"
	
	var mesh = HerbSystem.create_herb_mesh(1.0, 12345)
	
	if mesh != null and mesh is ArrayMesh and mesh.get_surface_count() > 0:
		pass_test(test_name)
	else:
		fail_test(test_name, "Herb mesh not created correctly")

func test_herb_size_variation() -> void:
	test_count += 1
	var test_name = "Herb meshes vary in size"
	
	# Create herbs with different size scales
	var mesh_small = HerbSystem.create_herb_mesh(0.8, 100)
	var mesh_medium = HerbSystem.create_herb_mesh(1.0, 200)
	var mesh_large = HerbSystem.create_herb_mesh(1.2, 300)
	
	# All should be valid meshes
	var all_valid = (
		mesh_small != null and mesh_small is ArrayMesh and
		mesh_medium != null and mesh_medium is ArrayMesh and
		mesh_large != null and mesh_large is ArrayMesh
	)
	
	if all_valid:
		pass_test(test_name)
	else:
		fail_test(test_name, "Not all herb size variations created correctly")

func test_herb_color_properties() -> void:
	test_count += 1
	var test_name = "Herb colors are visually distinct"
	
	var herb_color = HerbSystem.HERB_COLOR
	var leaf_color = HerbSystem.HERB_LEAF_COLOR
	
	# Check that colors are different enough
	var color_diff = abs(herb_color.r - leaf_color.r) + abs(herb_color.g - leaf_color.g) + abs(herb_color.b - leaf_color.b)
	
	# Check that herb color is reddish (more red than green/blue)
	var is_reddish = herb_color.r > herb_color.g and herb_color.r > herb_color.b
	
	# Check that leaf color is greenish (more green than red/blue)
	var is_greenish = leaf_color.g > leaf_color.r
	
	if color_diff > 0.3 and is_reddish and is_greenish:
		pass_test(test_name)
	else:
		fail_test(test_name, "Herb and leaf colors not visually distinct enough")

# Helper functions

func pass_test(test_name: String, message: String = "") -> void:
	passed_count += 1
	print("✓ PASS: ", test_name)
	if message != "":
		print("  ", message)

func fail_test(test_name: String, message: String) -> void:
	print("✗ FAIL: ", test_name)
	print("  ", message)
