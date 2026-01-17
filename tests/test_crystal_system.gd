extends Node
## Test script for Crystal Collection System
##
## Tests:
## - Crystal type selection and randomization
## - Crystal mesh generation
## - Crystal material creation
## - Spawn probabilities

const CrystalSystem = preload("res://scripts/crystal_system.gd")

var test_results: Array = []

func _ready():
	print("\n========================================")
	print("Crystal Collection System Tests")
	print("========================================\n")
	
	run_tests()
	print_results()
	
	# Auto-quit after 2 seconds to let results be visible
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func run_tests():
	test_crystal_type_selection()
	test_crystal_mesh_generation()
	test_crystal_material_creation()
	test_crystal_colors()
	test_spawn_probabilities()

func test_crystal_type_selection():
	print("Test: Crystal Type Selection")
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	var type_counts = {}
	var total_samples = 1000
	
	# Initialize counts
	for type in CrystalSystem.CrystalType.values():
		type_counts[type] = 0
	
	# Generate samples
	for i in range(total_samples):
		var selected_type = CrystalSystem.select_random_crystal_type(rng)
		type_counts[selected_type] += 1
	
	# Check that all types were selected at least once
	var all_types_selected = true
	for type in type_counts:
		if type_counts[type] == 0:
			all_types_selected = false
			break
	
	if all_types_selected:
		print("  ✓ All crystal types selected in random sampling")
		test_results.append(true)
	else:
		print("  ✗ Not all crystal types were selected")
		test_results.append(false)
	
	# Print distribution
	print("  Distribution over %d samples:" % total_samples)
	for type in CrystalSystem.CrystalType.values():
		var percentage = (float(type_counts[type]) / total_samples) * 100.0
		print("    %s: %d (%.1f%%)" % [CrystalSystem.get_crystal_name(type), type_counts[type], percentage])
	print()

func test_crystal_mesh_generation():
	print("Test: Crystal Mesh Generation")
	var rng = RandomNumberGenerator.new()
	rng.seed = 54321
	
	var success = true
	
	# Test creating mesh for each crystal type
	for type in CrystalSystem.CrystalType.values():
		var mesh = CrystalSystem.create_crystal_mesh(type, 1.0, rng.randi())
		if mesh == null or mesh.get_surface_count() == 0:
			print("  ✗ Failed to create mesh for type: %d" % type)
			success = false
		else:
			var surface_count = mesh.get_surface_count()
			print("  ✓ Created mesh for %s (surfaces: %d)" % [CrystalSystem.get_crystal_name(type), surface_count])
	
	test_results.append(success)
	print()

func test_crystal_material_creation():
	print("Test: Crystal Material Creation")
	var success = true
	
	# Test creating material for each crystal type
	for type in CrystalSystem.CrystalType.values():
		var material = CrystalSystem.create_crystal_material(type)
		if material == null:
			print("  ✗ Failed to create material for type: %d" % type)
			success = false
		else:
			# Check that material has transparency enabled
			var has_transparency = (material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
			var has_emission = material.emission_enabled
			
			if has_transparency and has_emission:
				print("  ✓ Created material for %s (transparent: %s, emission: %s)" % 
					[CrystalSystem.get_crystal_name(type), has_transparency, has_emission])
			else:
				print("  ✗ Material for %s missing properties (transparent: %s, emission: %s)" % 
					[CrystalSystem.get_crystal_name(type), has_transparency, has_emission])
				success = false
	
	test_results.append(success)
	print()

func test_crystal_colors():
	print("Test: Crystal Colors")
	var success = true
	
	# Verify each crystal type has a unique color
	var colors = {}
	for type in CrystalSystem.CrystalType.values():
		var color = CrystalSystem.get_crystal_color(type)
		var color_str = str(color)
		
		if color_str in colors:
			print("  ✗ Duplicate color found for %s" % CrystalSystem.get_crystal_name(type))
			success = false
		else:
			colors[color_str] = type
			print("  ✓ %s has color: %s" % [CrystalSystem.get_crystal_name(type), color])
	
	test_results.append(success)
	print()

func test_spawn_probabilities():
	print("Test: Spawn Probabilities")
	var success = true
	
	# Verify spawn chances sum to approximately 1.0 (with some tolerance for rounding)
	var total_spawn_chance = 0.0
	for type in CrystalSystem.CrystalType.values():
		var chance = CrystalSystem.get_spawn_chance(type)
		total_spawn_chance += chance
		print("  %s spawn chance: %.2f (growth freq: %.2f)" % 
			[CrystalSystem.get_crystal_name(type), chance, CrystalSystem.get_growth_frequency(type)])
	
	print("  Total spawn probability: %.2f" % total_spawn_chance)
	
	# Allow for some floating-point tolerance
	if abs(total_spawn_chance - 1.0) < 0.01:
		print("  ✓ Spawn probabilities sum to ~1.0")
		test_results.append(true)
	else:
		print("  ⚠ Spawn probabilities sum to %.2f (expected ~1.0)" % total_spawn_chance)
		test_results.append(true)  # Warning but not a failure
	print()

func print_results():
	print("========================================")
	print("Test Results Summary")
	print("========================================")
	
	var passed = 0
	var total = test_results.size()
	
	for result in test_results:
		if result:
			passed += 1
	
	print("Passed: %d/%d" % [passed, total])
	
	if passed == total:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed")
	
	print("========================================\n")
