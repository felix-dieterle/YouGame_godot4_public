extends Node

# Test suite for mobile controls, specifically verifying view control joystick visibility
# 
# IMPORTANT: This test must configure MobileControls with the same anchors and layout
# properties as used in main.tscn (PRESET_FULL_RECT with anchor_right=1.0, anchor_bottom=1.0)
# to ensure proper positioning and visibility of joystick elements.
#
# ENHANCED: Now uses realistic viewport size to catch Android-specific issues

const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")

var mobile_controls: Control
var screenshot_count = 0
var test_passed: int = 0
var test_failed: int = 0

# Android-like viewport size for realistic testing
const ANDROID_VIEWPORT_WIDTH: int = 1080
const ANDROID_VIEWPORT_HEIGHT: int = 2400

func _ready():
	print("=== Starting Mobile Controls Tests (Enhanced) ===")
	
	# Set realistic viewport size to match Android devices
	get_window().size = Vector2i(ANDROID_VIEWPORT_WIDTH, ANDROID_VIEWPORT_HEIGHT)
	await get_tree().process_frame  # Wait for resize to take effect
	
	print("Viewport size set to: %dx%d (Android-like)" % [ANDROID_VIEWPORT_WIDTH, ANDROID_VIEWPORT_HEIGHT])
	
	# Run unit tests
	test_mobile_controls_script_exists()
	test_look_joystick_creation()
	await test_look_joystick_visibility_visual()
	test_look_joystick_properties()
	test_joystick_positions()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Mobile Controls Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_mobile_controls_script_exists():
	print("\n--- Test: MobileControls Script Exists ---")
	
	# Verify the mobile controls script can be loaded
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if mobile_controls_script:
		assert_pass("MobileControls script loaded successfully")
		
		# Create an instance directly from the script
		mobile_controls = mobile_controls_script.new()
		
		if mobile_controls is Control:
			assert_pass("MobileControls extends Control")
		else:
			assert_fail("MobileControls should extend Control")
	else:
		assert_fail("Could not load MobileControls script")

func test_look_joystick_creation():
	print("\n--- Test: Look Joystick Creation ---")
	
	if not mobile_controls:
		assert_fail("MobileControls not initialized")
		return
	
	# Configure MobileControls to match the main.tscn scene configuration
	# This is critical for proper positioning and visibility
	mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls.anchor_right = 1.0
	mobile_controls.anchor_bottom = 1.0
	mobile_controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mobile_controls.grow_vertical = Control.GROW_DIRECTION_BOTH
	mobile_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# CRITICAL: Match main.tscn z_index setting for MobileControls parent
	mobile_controls.z_index = 10
	
	# Add mobile_controls to the tree so _ready gets called
	add_child(mobile_controls)
	await get_tree().process_frame
	
	# Check if the movement joystick variables are initialized
	if mobile_controls.joystick_base != null:
		assert_pass("joystick_base (movement) is initialized")
	else:
		assert_fail("joystick_base (movement) is null")
	
	if mobile_controls.joystick_stick != null:
		assert_pass("joystick_stick (movement) is initialized")
	else:
		assert_fail("joystick_stick (movement) is null")
	
	# Check if the look joystick variables are initialized
	if mobile_controls.look_joystick_base != null:
		assert_pass("look_joystick_base is initialized")
	else:
		assert_fail("look_joystick_base is null")
	
	if mobile_controls.look_joystick_stick != null:
		assert_pass("look_joystick_stick is initialized")
	else:
		assert_fail("look_joystick_stick is null")

func test_look_joystick_visibility_visual():
	print("\n--- Test: Look Joystick Visibility (Visual) ---")
	
	if not mobile_controls or not mobile_controls.look_joystick_base:
		assert_fail("Look joystick not available for visual test")
		return
	
	# Wait for rendering (reduced to 3 frames for simple visibility verification)
	await ScreenshotHelper.wait_for_render(3)
	
	# Capture screenshot showing the look joystick
	ScreenshotHelper.capture_screenshot("mobile_controls", "view_control_joystick")
	screenshot_count += 1
	
	assert_pass("Captured screenshot of view control joystick for visual verification")
	print("  Note: Screenshot saved to verify joystick is visible on screen")

func test_look_joystick_properties():
	print("\n--- Test: Look Joystick Properties ---")
	
	if not mobile_controls or not mobile_controls.look_joystick_base:
		assert_fail("Look joystick not available")
		return
	
	var look_base = mobile_controls.look_joystick_base
	var look_stick = mobile_controls.look_joystick_stick
	
	# Check visibility
	if look_base.visible:
		assert_pass("look_joystick_base is visible")
	else:
		assert_fail("look_joystick_base is not visible")
	
	if look_stick.visible:
		assert_pass("look_joystick_stick is visible")
	else:
		assert_fail("look_joystick_stick is not visible")
	
	# Check if in scene tree (which affects is_visible_in_tree)
	if look_base.is_inside_tree():
		assert_pass("look_joystick_base is in scene tree")
		
		if look_base.is_visible_in_tree():
			assert_pass("look_joystick_base is visible in tree")
		else:
			assert_fail("look_joystick_base is not visible in tree")
	else:
		assert_fail("look_joystick_base is not in scene tree")
	
	# Check size
	if look_base.size.x > 0 and look_base.size.y > 0:
		assert_pass("look_joystick_base has non-zero size: %.0fx%.0f" % [look_base.size.x, look_base.size.y])
	else:
		assert_fail("look_joystick_base has zero size")
	
	# Check that it has children (the visual panels)
	if look_base.get_child_count() > 0:
		assert_pass("look_joystick_base has %d children (visual elements)" % look_base.get_child_count())
	else:
		assert_fail("look_joystick_base has no children")
	
	# Check modulate (alpha channel)
	if look_base.modulate.a > 0:
		assert_pass("look_joystick_base modulate alpha: %.2f" % look_base.modulate.a)
	else:
		assert_fail("look_joystick_base has zero alpha")
	
	# Check z_index to ensure joystick renders above UI elements
	# CRITICAL: With MobileControls parent z_index = 10 (from main.tscn),
	# the effective z_index is parent (10) + child (60) = 70
	# This must be above UIManager children like version_label which has z_index=100
	# (UIManager parent has z_index=0, so version_label effective = 0 + 100 = 100)
	# For proper visibility on mobile, joystick needs effective z_index > 100
	var effective_z_index = mobile_controls.z_index + look_base.z_index
	if effective_z_index > 100:
		assert_pass("look_joystick effective z_index is %d (above UI elements with z_index 100)" % effective_z_index)
	else:
		assert_fail("look_joystick effective z_index is %d (should be > 100 to render above UI elements like version_label at 100)" % effective_z_index)

func test_joystick_positions():
	print("\n--- Test: Look Joystick Position ---")
	
	if not mobile_controls or not mobile_controls.look_joystick_base:
		assert_fail("Look joystick not available")
		return
	
	var look_base = mobile_controls.look_joystick_base
	var viewport_size = get_viewport().size
	
	# Read actual margin values from mobile_controls
	var look_margin_x = mobile_controls.look_joystick_margin_x
	var look_margin_y = mobile_controls.look_joystick_margin_y
	
	print("  Viewport size: %.0fx%.0f" % [viewport_size.x, viewport_size.y])
	print("  Look joystick margins: X=%.0f, Y=%.0f" % [look_margin_x, look_margin_y])
	print("  Look joystick position: (%.0f, %.0f)" % [look_base.position.x, look_base.position.y])
	print("  Look joystick global position: (%.0f, %.0f)" % [look_base.global_position.x, look_base.global_position.y])
	
	# With Android-like viewport, position tests are meaningful
	assert_true(viewport_size.x == ANDROID_VIEWPORT_WIDTH, 
		"Viewport width should be %d for Android testing" % ANDROID_VIEWPORT_WIDTH)
	assert_true(viewport_size.y == ANDROID_VIEWPORT_HEIGHT,
		"Viewport height should be %d for Android testing" % ANDROID_VIEWPORT_HEIGHT)
	
	# Check if position is in the right area (bottom-right quadrant)
	var is_right_side = look_base.position.x > viewport_size.x / 2
	var is_bottom = look_base.position.y > viewport_size.y / 2
	
	if is_right_side:
		assert_pass("Look joystick is on the right side of screen")
	else:
		assert_fail("Look joystick should be on the right side of screen (pos.x=%.0f, mid=%.0f)" % [look_base.position.x, viewport_size.x / 2])
	
	if is_bottom:
		assert_pass("Look joystick is on the bottom of screen")
	else:
		assert_fail("Look joystick should be on the bottom of screen (pos.y=%.0f, mid=%.0f)" % [look_base.position.y, viewport_size.y / 2])
	
	# Verify it's within viewport bounds (accounting for joystick size)
	var joystick_right_edge = look_base.global_position.x + look_base.size.x
	var joystick_bottom_edge = look_base.global_position.y + look_base.size.y
	
	if look_base.global_position.x >= 0 and joystick_right_edge <= viewport_size.x:
		assert_pass("Look joystick X position is fully within viewport")
	else:
		assert_fail("Look joystick extends outside viewport horizontally (pos: %.0f, right edge: %.0f, viewport: %.0f)" % [look_base.global_position.x, joystick_right_edge, viewport_size.x])
	
	if look_base.global_position.y >= 0 and joystick_bottom_edge <= viewport_size.y:
		assert_pass("Look joystick Y position is fully within viewport")
	else:
		assert_fail("Look joystick extends outside viewport vertically (pos: %.0f, bottom edge: %.0f, viewport: %.0f)" % [look_base.global_position.y, joystick_bottom_edge, viewport_size.y])

# Helper functions for tracking test results
func assert_pass(message: String):
	print("  ✓ PASS: ", message)
	test_passed += 1

func assert_fail(message: String):
	print("  ✗ FAIL: ", message)
	test_failed += 1
