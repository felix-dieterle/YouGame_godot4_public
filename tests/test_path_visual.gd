extends Node3D

## Visual test for path rendering and generation
## This test creates chunks with paths, renders them, and captures screenshots
## to demonstrate how the path generation system works across chunks

const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")
const PathSystem = preload("res://scripts/systems/world/path_system.gd")
const Chunk = preload("res://scripts/systems/world/chunk.gd")

var screenshot_count = 0
var world_seed = 12345

func _ready():
	print("=== Starting Path Visual Test with Screenshots ===")
	
	# Set up a basic 3D environment for rendering
	await setup_3d_environment()
	
	# Create and render path chunks
	await create_path_visualization()
	
	print("=== Path Visual Test Completed ===")
	print("Total screenshots captured: ", screenshot_count)
	get_tree().quit()

## Set up 3D environment with camera and lighting
func setup_3d_environment():
	print("\n--- Setting up 3D Environment ---")
	
	# Create camera
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(32, 50, 32)  # Position to view multiple chunks
	camera.look_at(Vector3(32, 0, 32), Vector3.UP)
	add_child(camera)
	
	# Make camera current
	camera.current = true
	
	# Create directional light (sun)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.0
	add_child(light)
	
	# Create environment for better rendering
	var world_env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	world_env.environment = environment
	add_child(world_env)
	
	print("  3D environment ready")

## Create and render paths across multiple chunks
func create_path_visualization():
	print("\n--- Creating Path Visualization ---")
	
	# Clear any existing paths
	PathSystem.clear_all_paths()
	
	# Generate a grid of chunks that should contain paths
	# We start from adjacent chunks to (0,0) since (0,0) has no paths
	var chunks_to_render = [
		Vector2i(1, 0),   # East of origin - should have initial path
		Vector2i(2, 0),   # Further east - path should continue
		Vector2i(3, 0),   # Even further - path should continue
		Vector2i(1, 1),   # Southeast - may have paths
		Vector2i(0, 1),   # South of origin - should have initial path
		Vector2i(0, 2),   # Further south - path should continue
	]
	
	print("  Generating chunks with paths...")
	var chunk_objects = []
	
	for chunk_pos in chunks_to_render:
		# Get path segments for this chunk
		var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
		
		print("    Chunk ", chunk_pos, " has ", segments.size(), " path segment(s)")
		
		# Create and generate the chunk
		var chunk = Chunk.new(chunk_pos.x, chunk_pos.y, world_seed)
		chunk.generate()
		add_child(chunk)
		chunk_objects.append(chunk)
	
	# Wait for rendering
	print("  Waiting for initial render...")
	await ScreenshotHelper.wait_for_render(10)
	
	# Capture overview screenshot from current camera position
	print("  Capturing overview screenshot...")
	ScreenshotHelper.capture_screenshot("path_visual", "overview_from_above")
	screenshot_count += 1
	
	# Get camera for repositioning
	var camera = get_node_or_null("Camera3D")
	if camera:
		# Take screenshot from different angles
		
		# View 1: Looking east along the main path
		camera.position = Vector3(0, 15, 16)
		camera.look_at(Vector3(64, 0, 16), Vector3.UP)
		await ScreenshotHelper.wait_for_render(5)
		ScreenshotHelper.capture_screenshot("path_visual", "view_along_east_path")
		screenshot_count += 1
		
		# View 2: Looking south along the path
		camera.position = Vector3(16, 15, 0)
		camera.look_at(Vector3(16, 0, 64), Vector3.UP)
		await ScreenshotHelper.wait_for_render(5)
		ScreenshotHelper.capture_screenshot("path_visual", "view_along_south_path")
		screenshot_count += 1
		
		# View 3: Angled view to see path continuity
		camera.position = Vector3(48, 35, 48)
		camera.look_at(Vector3(24, 0, 24), Vector3.UP)
		await ScreenshotHelper.wait_for_render(5)
		ScreenshotHelper.capture_screenshot("path_visual", "angled_view_path_continuity")
		screenshot_count += 1
		
		# View 4: Close-up of a path segment
		camera.position = Vector3(48, 8, 20)
		camera.look_at(Vector3(48, 0, 16), Vector3.UP)
		await ScreenshotHelper.wait_for_render(5)
		ScreenshotHelper.capture_screenshot("path_visual", "closeup_path_detail")
		screenshot_count += 1
	
	# Print path statistics
	print("\n--- Path Generation Statistics ---")
	print("  Total path segments generated: ", PathSystem.get_total_segments())
	print("  Chunks with paths: ", PathSystem.chunk_segments.size())
	
	# Print detailed information about each chunk's paths
	for chunk_pos in chunks_to_render:
		if PathSystem.chunk_segments.has(chunk_pos):
			var segment_ids = PathSystem.chunk_segments[chunk_pos]
			print("  Chunk ", chunk_pos, ":")
			for seg_id in segment_ids:
				if PathSystem.all_segments.has(seg_id):
					var segment = PathSystem.all_segments[seg_id]
					var type_name = _get_path_type_name(segment.path_type)
					print("    - Segment ", seg_id, " (", type_name, "): from ", segment.start_pos, " to ", segment.end_pos)
					if segment.is_endpoint:
						print("      [ENDPOINT]")
	
	# Cleanup
	for chunk in chunk_objects:
		chunk.queue_free()
	
	print("PASS: Path visualization complete with ", screenshot_count, " screenshots")

## Helper to get path type name
func _get_path_type_name(path_type) -> String:
	match path_type:
		PathSystem.PathType.MAIN_PATH:
			return "Main Path"
		PathSystem.PathType.BRANCH:
			return "Branch"
		PathSystem.PathType.FOREST_PATH:
			return "Forest Path"
		PathSystem.PathType.VILLAGE_PATH:
			return "Village Path"
		_:
			return "Unknown"
