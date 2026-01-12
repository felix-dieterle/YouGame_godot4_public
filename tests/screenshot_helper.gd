extends Node

## Screenshot Helper for Tests
## This utility helps test scenes capture screenshots for visual verification in PRs

# Directory where screenshots will be saved
const SCREENSHOT_DIR = "user://test_screenshots/"

# Initialize screenshot directory
static func init_screenshot_dir():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("test_screenshots"):
		dir.make_dir("test_screenshots")
		print("Created screenshot directory: ", SCREENSHOT_DIR)

# Capture a screenshot of the current viewport
static func capture_screenshot(scene_name: String, description: String = "") -> String:
	init_screenshot_dir()
	
	# Generate filename with timestamp
	var time = Time.get_datetime_dict_from_system()
	var filename = "%s_%s" % [scene_name, description] if description else scene_name
	filename = filename.replace(" ", "_").to_lower()
	var filepath = "%s%s.png" % [SCREENSHOT_DIR, filename]
	
	# Capture the viewport
	var viewport = Engine.get_main_loop().root.get_viewport()
	var image = viewport.get_texture().get_image()
	
	# Save the image
	var error = image.save_png(filepath)
	
	if error == OK:
		print("Screenshot saved: ", filepath)
		# Also print the actual file system path for CI
		var actual_path = ProjectSettings.globalize_path(filepath)
		print("Screenshot filesystem path: ", actual_path)
		return actual_path
	else:
		print("Failed to save screenshot: ", error)
		return ""

# Wait for frames to ensure scene is fully rendered
static func wait_for_render(frames: int = 3):
	for i in range(frames):
		await Engine.get_main_loop().process_frame
