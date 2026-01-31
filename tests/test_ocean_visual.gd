extends Node

# Visual test for ocean and lighthouse features
# Demonstrates ocean chunks with coastal lighthouses

const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")
const CHUNK = preload("res://scripts/systems/world/chunk.gd")
const WorldManager = preload("res://scripts/systems/world/world_manager.gd")

var screenshot_count = 0

func _ready():
	print("=== Starting Ocean & Lighthouse Visual Test ===")
	
	# Create a visual scene with ocean and coastal chunks
	await create_ocean_scene()
	
	print("=== Ocean & Lighthouse Visual Test Completed ===")
	get_tree().quit()

func create_ocean_scene():
	print("\n--- Creating Ocean Scene ---")
	
	# Wait for initial render
	await ScreenshotHelper.wait_for_render(5)
	
	# Create camera for visualization
	var camera = Camera3D.new()
	camera.position = Vector3(32, 40, 32)  # Elevated view
	camera.rotation_degrees = Vector3(-45, 45, 0)  # Look down at angle
	add_child(camera)
	
	# Create directional light for better visibility
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)
	
	# Capture initial state
	ScreenshotHelper.capture_screenshot("ocean_lighthouse_test", "initial_setup")
	screenshot_count += 1
	
	# Create a grid of chunks including ocean areas
	# Ocean typically appears in low-elevation areas (chunk coordinates with low noise)
	var test_chunks = []
	
	# Create chunks in a pattern likely to show ocean and coast
	for x in range(-2, 3):
		for z in range(-2, 3):
			var chunk = CHUNK.new(x, z, 12345)
			add_child(chunk)
			chunk.generate()
			test_chunks.append(chunk)
			
			print("  Chunk [%d,%d]: biome=%s, ocean=%s, lighthouses=%d" % [
				x, z, chunk.biome, chunk.is_ocean, chunk.placed_lighthouses.size()
			])
	
	# Wait for rendering
	await ScreenshotHelper.wait_for_render(5)
	
	# Capture ocean and lighthouse scene
	ScreenshotHelper.capture_screenshot("ocean_lighthouse_test", "ocean_with_lighthouses")
	screenshot_count += 1
	
	# Count statistics
	var ocean_chunks = 0
	var coastal_chunks = 0
	var total_lighthouses = 0
	
	for chunk in test_chunks:
		if chunk.is_ocean:
			ocean_chunks += 1
		if chunk.placed_lighthouses.size() > 0:
			coastal_chunks += 1
			total_lighthouses += chunk.placed_lighthouses.size()
	
	print("\n--- Ocean Scene Statistics ---")
	print("  Total chunks: %d" % test_chunks.size())
	print("  Ocean chunks: %d" % ocean_chunks)
	print("  Coastal chunks with lighthouses: %d" % coastal_chunks)
	print("  Total lighthouses placed: %d" % total_lighthouses)
	
	# Cleanup
	for chunk in test_chunks:
		chunk.queue_free()
	
	print("PASS: Ocean scene created and captured (%d screenshots)" % screenshot_count)
