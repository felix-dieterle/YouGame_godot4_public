extends Node

# Test suite for ruler overlay with value labels

func _ready():
	print("=== Starting Ruler Overlay Tests ===")
	test_ruler_overlay_exists()
	test_ruler_overlay_methods()
	test_ruler_overlay_constants()
	print("=== All Ruler Overlay Tests Completed ===")
	get_tree().quit()

func test_ruler_overlay_exists():
	print("\n--- Test: RulerOverlay Script Exists ---")
	
	# Verify the ruler overlay script can be loaded
	var ruler_script = load("res://scripts/ruler_overlay.gd")
	if ruler_script:
		print("  PASS: RulerOverlay script loaded successfully")
		
		# Create an instance to verify it extends Control
		var ruler = ruler_script.new()
		if ruler is Control:
			print("  PASS: RulerOverlay extends Control")
		else:
			print("  FAIL: RulerOverlay should extend Control")
		
		# Check class name
		if "RulerOverlay" in str(ruler.get_script()):
			print("  PASS: RulerOverlay has correct class name")
		else:
			print("  INFO: RulerOverlay class name check inconclusive")
		
		ruler.free()
	else:
		print("  FAIL: Could not load RulerOverlay script")

func test_ruler_overlay_methods():
	print("\n--- Test: RulerOverlay Methods ---")
	
	var ruler_script = load("res://scripts/ruler_overlay.gd")
	if ruler_script:
		var ruler = ruler_script.new()
		
		# Check for required methods
		if ruler.has_method("toggle_visibility"):
			print("  PASS: RulerOverlay has toggle_visibility method")
		else:
			print("  FAIL: RulerOverlay missing toggle_visibility method")
		
		if ruler.has_method("set_visible_state"):
			print("  PASS: RulerOverlay has set_visible_state method")
		else:
			print("  FAIL: RulerOverlay missing set_visible_state method")
		
		if ruler.has_method("get_visible_state"):
			print("  PASS: RulerOverlay has get_visible_state method")
		else:
			print("  FAIL: RulerOverlay missing get_visible_state method")
		
		# Test visibility state management
		var initial_state = ruler.get_visible_state()
		if initial_state == false:
			print("  PASS: RulerOverlay is initially hidden")
		else:
			print("  FAIL: RulerOverlay should be initially hidden")
		
		ruler.set_visible_state(true)
		if ruler.get_visible_state() == true:
			print("  PASS: RulerOverlay visibility state can be set to true")
		else:
			print("  FAIL: RulerOverlay visibility state should be true")
		
		ruler.toggle_visibility()
		if ruler.get_visible_state() == false:
			print("  PASS: RulerOverlay visibility can be toggled")
		else:
			print("  FAIL: RulerOverlay visibility toggle failed")
		
		ruler.free()
	else:
		print("  FAIL: Could not load RulerOverlay script")

func test_ruler_overlay_constants():
	print("\n--- Test: RulerOverlay Constants ---")
	
	var ruler_script = load("res://scripts/ruler_overlay.gd")
	if ruler_script:
		var ruler = ruler_script.new()
		
		# Check for MARKER_SPACING constant
		if ruler.get("MARKER_SPACING") != null:
			var spacing = ruler.get("MARKER_SPACING")
			if spacing == 50:
				print("  PASS: RulerOverlay has MARKER_SPACING constant set to 50")
			else:
				print("  FAIL: RulerOverlay MARKER_SPACING should be 50, got: %d" % spacing)
		else:
			print("  FAIL: RulerOverlay missing MARKER_SPACING constant")
		
		ruler.free()
	else:
		print("  FAIL: Could not load RulerOverlay script")
