extends Node3D

## Visual Test for Fishing Boat
## 
## Creates a test scene with chunks and camera to visually verify
## the fishing boat placement on coastal areas near spawn

const Chunk = preload("res://scripts/chunk.gd")
const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")

# Configuration
const GRID_SIZE = 5  # 5x5 grid of chunks
const WORLD_SEED = 12345

# Camera
var camera: Camera3D
var camera_height = 30.0
var camera_distance = 50.0

func _ready():
	print("=== Fishing Boat Visual Test ===")
	
	# Create camera
	camera = Camera3D.new()
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)
	
	# Create directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 10, 0)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.0
	add_child(light)
	
	# Generate chunks
	print("Generating %dx%d chunk grid..." % [GRID_SIZE, GRID_SIZE])
	var chunks_generated = 0
	var ocean_chunks = 0
	var coastal_chunks = 0
	var boat_chunks = 0
	
	var start_offset = -GRID_SIZE / 2
	
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var chunk_x = start_offset + x
			var chunk_z = start_offset + z
			
			var chunk = Chunk.new(chunk_x, chunk_z, WORLD_SEED)
			add_child(chunk)
			chunk.generate()
			chunks_generated += 1
			
			# Count ocean chunks
			if chunk.is_ocean:
				ocean_chunks += 1
			
			# Count coastal chunks (has ocean neighbor)
			if not chunk.is_ocean:
				# Check neighbors
				var has_ocean_neighbor = false
				for dx in [-1, 0, 1]:
					for dz in [-1, 0, 1]:
						if dx == 0 and dz == 0:
							continue
						var nx = chunk_x + dx
						var nz = chunk_z + dz
						# Estimate if neighbor is ocean
						var neighbor_height = chunk._get_estimated_chunk_height(Vector2i(nx, nz))
						if neighbor_height <= Chunk.OCEAN_LEVEL:
							has_ocean_neighbor = true
							break
					if has_ocean_neighbor:
						break
				
				if has_ocean_neighbor:
					coastal_chunks += 1
			
			# Check if this chunk has a boat
			if chunk.placed_fishing_boat != null:
				boat_chunks += 1
				print("  - Fishing boat placed in chunk (%d, %d)" % [chunk_x, chunk_z])
	
	print("Chunks generated: %d" % chunks_generated)
	print("Ocean chunks: %d" % ocean_chunks)
	print("Coastal chunks: %d" % coastal_chunks)
	print("Chunks with fishing boat: %d" % boat_chunks)
	
	# Wait for rendering
	await get_tree().create_timer(0.5).timeout
	
	# Take screenshot
	print("Taking screenshot...")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	ScreenshotHelper.capture_screenshot("fishing_boat_visual", "coastal_chunks")
	
	# Wait a moment to ensure screenshot is saved
	await get_tree().create_timer(0.5).timeout
	
	print("=== Fishing Boat Visual Test Completed ===")
	get_tree().quit()

func _process(_delta):
	# Rotate camera slowly for better view
	if camera:
		camera.rotation.y += 0.002
