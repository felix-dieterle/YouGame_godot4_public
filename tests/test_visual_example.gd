extends Node

# Example visual test that demonstrates screenshot capture
# This test creates a simple scene with visual elements and captures screenshots

const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")
const CHUNK = preload("res://scripts/systems/world/chunk.gd")

var screenshot_count = 0

func _ready():
	print("=== Starting Visual Example Test with Screenshots ===")
	
	# Create a simple 3D scene for testing
	await create_visual_scene()
	
	print("=== Visual Example Test Completed ===")
	get_tree().quit()

func create_visual_scene():
	print("\n--- Creating Example Visual Scene ---")
	
	# Wait for initial render
	await ScreenshotHelper.wait_for_render(5)
	
	# Capture initial state
	ScreenshotHelper.capture_screenshot("example_visual_test", "initial_state")
	screenshot_count += 1
	
	# Create a simple 3D scene with a chunk
	var chunk = CHUNK.new(0, 0, 12345)
	chunk.generate()
	
	print("  Created chunk with biome: %s, landmark: %s" % [chunk.biome, chunk.landmark_type])
	
	# Wait a bit more for any rendering
	await ScreenshotHelper.wait_for_render(3)
	
	# Capture after chunk creation
	ScreenshotHelper.capture_screenshot("example_visual_test", "with_chunk_%s" % chunk.biome)
	screenshot_count += 1
	
	# Cleanup
	chunk.free()
	
	print("PASS: Captured %d screenshots for visual verification" % screenshot_count)
