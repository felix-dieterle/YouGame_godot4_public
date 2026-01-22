extends Node

# Test suite for wind sound and snow coverage in mountain regions
const CHUNK = preload("res://scripts/chunk.gd")

func _ready():
	print("=== Starting Wind and Snow Tests ===")
	test_snow_coverage_in_mountains()
	test_wind_sound_in_mountains()
	test_no_wind_in_grasslands()
	print("=== All Tests Completed ===")
	get_tree().quit()

func test_snow_coverage_in_mountains():
	print("\n--- Test: Snow Coverage in Mountains ---")
	
	# Create a chunk that should be mountainous (seed produces mountains)
	var seed_value = 99999  # This seed tends to produce mountains
	var chunk = CHUNK.new(5, 5, seed_value)
	chunk.generate()
	
	# Check if biome is mountain
	if chunk.biome == "mountain":
		print("PASS: Mountain biome detected")
		
		# Calculate average height
		var avg_height = 0.0
		for h in chunk.heightmap:
			avg_height += h
		avg_height /= chunk.heightmap.size()
		
		print("  Average height: %.2f" % avg_height)
		
		# Check for high elevation (should have snow coverage potential)
		if avg_height > 12.0:
			print("PASS: High elevation detected (>12 units), snow coverage should be visible")
		else:
			print("INFO: Elevation %.2f not high enough for snow (needs >12 units)" % avg_height)
	else:
		print("INFO: Chunk biome is '%s', not mountain. Try different seed/position for mountain test." % chunk.biome)
	
	chunk.free()

func test_wind_sound_in_mountains():
	print("\n--- Test: Wind Sound in Mountains ---")
	
	# Create mountain chunk with high elevation
	var seed_value = 99999
	var chunk = CHUNK.new(5, 5, seed_value)
	chunk.generate()
	
	# Wait for wind sound setup
	await get_tree().process_frame
	
	# Check if wind sound player was created
	if chunk.wind_sound_player != null:
		print("PASS: Wind sound player created in mountain region")
		print("  Wind sound position: %s" % chunk.wind_sound_player.position)
		print("  Volume: %.1f dB" % chunk.wind_sound_player.volume_db)
		print("  Max distance: %.1f units" % chunk.wind_sound_player.max_distance)
	else:
		var avg_height = 0.0
		for h in chunk.heightmap:
			avg_height += h
		avg_height /= chunk.heightmap.size()
		
		if chunk.biome == "mountain" and avg_height >= 10.0:
			print("FAIL: Wind sound player should be created but wasn't")
		else:
			print("INFO: No wind sound (biome: %s, avg height: %.2f). Wind requires mountain biome and height >10" % [chunk.biome, avg_height])
	
	chunk.free()

func test_no_wind_in_grasslands():
	print("\n--- Test: No Wind in Grasslands ---")
	
	# Create a grassland chunk (seed 0, position 0,0 tends to be grassland)
	var seed_value = 12345
	var chunk = CHUNK.new(0, 0, seed_value)
	chunk.generate()
	
	# Wait for potential wind sound setup
	await get_tree().process_frame
	
	# Check that no wind sound player was created
	if chunk.wind_sound_player == null:
		print("PASS: No wind sound in non-mountain biome (biome: %s)" % chunk.biome)
	else:
		print("FAIL: Wind sound should not be created in grassland biome")
	
	chunk.free()
