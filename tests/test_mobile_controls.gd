extends Node

# Test suite for mobile controls, specifically verifying view control joystick visibility

const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")

var mobile_controls: Control
var screenshot_count = 0

func _ready():
	print("=== Starting Mobile Controls Tests ===")
	
	# Run unit tests
	test_mobile_controls_script_exists()
	test_look_joystick_creation()
	await test_look_joystick_visibility_visual()
	test_look_joystick_properties()
	test_joystick_positions()
	
	print("=== All Mobile Controls Tests Completed ===")
	get_tree().quit()

func test_mobile_controls_script_exists():
	print("\n--- Test: MobileControls Script Exists ---")
	
	# Verify the mobile controls script can be loaded
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if mobile_controls_script:
		print("  PASS: MobileControls script loaded successfully")
		
		# Create an instance to verify it extends Control
		mobile_controls = Control.new()
		mobile_controls.set_script(mobile_controls_script)
		
		if mobile_controls is Control:
			print("  PASS: MobileControls extends Control")
		else:
			print("  FAIL: MobileControls should extend Control")
	else:
		print("  FAIL: Could not load MobileControls script")

func test_look_joystick_creation():
	print("\n--- Test: Look Joystick Creation ---")
	
	if not mobile_controls:
		print("  FAIL: MobileControls not initialized")
		return
	
	# Add mobile_controls to the tree so _ready gets called
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Check if the look joystick variables are accessible
	if mobile_controls.has("look_joystick_base"):
		print("  PASS: look_joystick_base variable exists")
		
		if mobile_controls.look_joystick_base != null:
			print("  PASS: look_joystick_base is initialized")
		else:
			print("  FAIL: look_joystick_base is null")
	else:
		print("  FAIL: look_joystick_base variable not found")
	
	if mobile_controls.has("look_joystick_stick"):
		print("  PASS: look_joystick_stick variable exists")
		
		if mobile_controls.look_joystick_stick != null:
			print("  PASS: look_joystick_stick is initialized")
		else:
			print("  FAIL: look_joystick_stick is null")
	else:
		print("  FAIL: look_joystick_stick variable not found")

func test_look_joystick_visibility_visual():
	print("\n--- Test: Look Joystick Visibility (Visual) ---")
	
	if not mobile_controls or not mobile_controls.look_joystick_base:
		print("  FAIL: Look joystick not available for visual test")
		return
	
	# Wait for rendering
	await ScreenshotHelper.wait_for_render(5)
	
	# Capture screenshot showing the look joystick
	ScreenshotHelper.capture_screenshot("mobile_controls", "view_control_joystick")
	screenshot_count += 1
	
	print("  PASS: Captured screenshot of view control joystick for visual verification")
	print("  Note: Screenshot saved to verify joystick is visible on screen")

func test_look_joystick_properties():
	print("\n--- Test: Look Joystick Properties ---")
	
	if not mobile_controls or not mobile_controls.look_joystick_base:
		print("  FAIL: Look joystick not available")
		return
	
	var look_base = mobile_controls.look_joystick_base
	var look_stick = mobile_controls.look_joystick_stick
	
	# Check visibility
	if look_base.visible:
		print("  PASS: look_joystick_base is visible")
	else:
		print("  FAIL: look_joystick_base is not visible")
	
	if look_stick.visible:
		print("  PASS: look_joystick_stick is visible")
	else:
		print("  FAIL: look_joystick_stick is not visible")
	
	# Check if in scene tree (which affects is_visible_in_tree)
	if look_base.is_inside_tree():
		print("  PASS: look_joystick_base is in scene tree")
		
		if look_base.is_visible_in_tree():
			print("  PASS: look_joystick_base is visible in tree")
		else:
			print("  FAIL: look_joystick_base is not visible in tree")
	else:
		print("  FAIL: look_joystick_base is not in scene tree")
	
	# Check size
	if look_base.size.x > 0 and look_base.size.y > 0:
		print("  PASS: look_joystick_base has non-zero size: %.0fx%.0f" % [look_base.size.x, look_base.size.y])
	else:
		print("  FAIL: look_joystick_base has zero size")
	
	# Check that it has children (the visual panels)
	if look_base.get_child_count() > 0:
		print("  PASS: look_joystick_base has %d children (visual elements)" % look_base.get_child_count())
	else:
		print("  FAIL: look_joystick_base has no children")
	
	# Check modulate (alpha channel)
	if look_base.modulate.a > 0:
		print("  PASS: look_joystick_base modulate alpha: %.2f" % look_base.modulate.a)
	else:
		print("  FAIL: look_joystick_base has zero alpha")

func test_joystick_positions():
	print("\n--- Test: Look Joystick Position ---")
	
	if not mobile_controls or not mobile_controls.look_joystick_base:
		print("  FAIL: Look joystick not available")
		return
	
	var look_base = mobile_controls.look_joystick_base
	var viewport_size = get_viewport().size
	
	# The look joystick should be positioned in the bottom-right corner
	# based on the code: viewport_size.x - look_joystick_margin_x, viewport_size.y - look_joystick_margin_y
	
	print("  Viewport size: %.0fx%.0f" % [viewport_size.x, viewport_size.y])
	print("  Look joystick position: (%.0f, %.0f)" % [look_base.position.x, look_base.position.y])
	print("  Look joystick global position: (%.0f, %.0f)" % [look_base.global_position.x, look_base.global_position.y])
	
	# Check if position is in the right area (bottom-right quadrant)
	var is_right_side = look_base.position.x > viewport_size.x / 2
	var is_bottom = look_base.position.y > viewport_size.y / 2
	
	if is_right_side:
		print("  PASS: Look joystick is on the right side of screen")
	else:
		print("  FAIL: Look joystick should be on the right side of screen")
	
	if is_bottom:
		print("  PASS: Look joystick is on the bottom of screen")
	else:
		print("  FAIL: Look joystick should be on the bottom of screen")
	
	# Verify it's within viewport bounds
	if look_base.global_position.x >= 0 and look_base.global_position.x < viewport_size.x:
		print("  PASS: Look joystick X position is within viewport")
	else:
		print("  FAIL: Look joystick X position is outside viewport")
	
	if look_base.global_position.y >= 0 and look_base.global_position.y < viewport_size.y:
		print("  PASS: Look joystick Y position is within viewport")
	else:
		print("  FAIL: Look joystick Y position is outside viewport")
