extends Node

## Visual Verification: Ocean Distance-Based Generation
## 
## This script creates a grid of chunks and prints which ones are ocean
## to visually verify that ocean appears at the expected distance

const Chunk = preload("res://scripts/systems/world/chunk.gd")

func _ready():
	print("=== Ocean Distance Verification ===")
	print("OCEAN_START_DISTANCE = %.1f units (%.1f chunks)" % [Chunk.OCEAN_START_DISTANCE, Chunk.OCEAN_START_DISTANCE / Chunk.CHUNK_SIZE])
	print("")
	
	# Test chunks in a grid pattern
	var test_positions = [
		Vector2i(0, 0),   # Origin
		Vector2i(1, 0),   # 1 chunk east
		Vector2i(2, 0),   # 2 chunks east
		Vector2i(3, 0),   # 3 chunks east
		Vector2i(4, 0),   # 4 chunks east (128 units)
		Vector2i(5, 0),   # 5 chunks east (160 units) - should be ocean
		Vector2i(6, 0),   # 6 chunks east (192 units) - should be ocean
		Vector2i(0, 5),   # 5 chunks north (160 units) - should be ocean
		Vector2i(3, 4),   # 3,4 diagonal (160 units) - should be ocean
		Vector2i(2, 2),   # 2,2 diagonal (90.5 units)
	]
	
	print("Chunk Position | Distance (units) | Is Ocean? | Biome")
	print("-" * 60)
	
	for pos in test_positions:
		var chunk = Chunk.new(pos.x, pos.y, 12345)
		add_child(chunk)
		chunk.generate()
		
		await get_tree().process_frame
		
		var chunk_world_center = Vector2(pos.x * Chunk.CHUNK_SIZE, pos.y * Chunk.CHUNK_SIZE)
		var distance = chunk_world_center.length()
		
		print("(%2d, %2d)       | %8.1f        | %-9s | %s" % [
			pos.x, pos.y, distance, 
			"YES" if chunk.is_ocean else "NO",
			chunk.biome
		])
		
		# Verify chunks beyond OCEAN_START_DISTANCE are ocean
		if distance >= Chunk.OCEAN_START_DISTANCE:
			assert(chunk.is_ocean, "Chunk at distance %.1f should be ocean" % distance)
		
		chunk.queue_free()
	
	print("")
	print("=== Verification Complete ===")
	print("✓ All chunks beyond %.1f units are correctly marked as ocean" % Chunk.OCEAN_START_DISTANCE)
	print("✓ Ocean is now discoverable by traveling ~5 chunks from spawn")
	
	get_tree().quit()
