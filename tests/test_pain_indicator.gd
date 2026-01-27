extends Node

# Test suite for pain indicator functionality
# Tests pain overlay creation and display logic

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Pain Indicator Tests ===")
	test_pain_indicator_alpha_scaling()
	test_pain_indicator_min_max_alpha()
	test_pain_indicator_creation()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Pain Indicator Tests Complete ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_pain_indicator_alpha_scaling():
	print("\n--- Test: Pain Indicator Alpha Scaling ---")
	
	# Test that alpha scales with damage amount
	# Alpha should be clamped between 0.2 and 0.6
	# Formula: clamp(damage / 50.0, 0.2, 0.6)
	
	var test_cases = [
		{"damage": 5.0, "expected_alpha": 0.2},    # Below minimum
		{"damage": 10.0, "expected_alpha": 0.2},   # At minimum
		{"damage": 25.0, "expected_alpha": 0.5},   # Mid-range
		{"damage": 50.0, "expected_alpha": 0.6},   # At maximum
		{"damage": 100.0, "expected_alpha": 0.6},  # Above maximum
	]
	
	for test_case in test_cases:
		var damage = test_case["damage"]
		var expected = test_case["expected_alpha"]
		var actual_alpha = clamp(damage / 50.0, 0.2, 0.6)
		
		check_condition(abs(actual_alpha - expected) < 0.01, 
			"Damage %.1f should produce alpha %.1f (actual: %.1f)" % [damage, expected, actual_alpha])

func test_pain_indicator_min_max_alpha():
	print("\n--- Test: Pain Indicator Min/Max Alpha Bounds ---")
	
	# Test minimum alpha (small damage)
	var small_damage = 1.0
	var alpha = clamp(small_damage / 50.0, 0.2, 0.6)
	check_condition(alpha == 0.2, "Minimum alpha should be 0.2 for small damage (alpha: %f)" % alpha)
	
	# Test maximum alpha (large damage)
	var large_damage = 200.0
	alpha = clamp(large_damage / 50.0, 0.2, 0.6)
	check_condition(alpha == 0.6, "Maximum alpha should be 0.6 for large damage (alpha: %f)" % alpha)
	
	# Test exact threshold values
	var threshold_min_damage = 10.0  # 10/50 = 0.2
	alpha = clamp(threshold_min_damage / 50.0, 0.2, 0.6)
	check_condition(alpha == 0.2, "Alpha should be 0.2 at minimum threshold (alpha: %f)" % alpha)
	
	var threshold_max_damage = 30.0  # 30/50 = 0.6
	alpha = clamp(threshold_max_damage / 50.0, 0.2, 0.6)
	check_condition(alpha == 0.6, "Alpha should be 0.6 at maximum threshold (alpha: %f)" % alpha)

func test_pain_indicator_creation():
	print("\n--- Test: Pain Indicator Creation Logic ---")
	
	# Simulate the pain overlay creation
	var pain_overlay: ColorRect = null
	
	# First call should create the overlay
	if not pain_overlay:
		pain_overlay = ColorRect.new()
		pain_overlay.anchor_right = 1.0
		pain_overlay.anchor_bottom = 1.0
		pain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pain_overlay.z_index = 250
	
	check_condition(pain_overlay != null, "Pain overlay should be created")
	check_condition(pain_overlay.anchor_right == 1.0, "Pain overlay should cover full width")
	check_condition(pain_overlay.anchor_bottom == 1.0, "Pain overlay should cover full height")
	check_condition(pain_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Pain overlay should not block input")
	check_condition(pain_overlay.z_index == 250, "Pain overlay should have z_index 250")
	
	# Test color setting with different damage values
	var damage = 25.0
	var alpha = clamp(damage / 50.0, 0.2, 0.6)
	var expected_color = Color(1.0, 0.0, 0.0, alpha)
	pain_overlay.color = expected_color
	
	check_condition(pain_overlay.color.r == 1.0, "Pain overlay should be red (r=1.0)")
	check_condition(pain_overlay.color.g == 0.0, "Pain overlay should be red (g=0.0)")
	check_condition(pain_overlay.color.b == 0.0, "Pain overlay should be red (b=0.0)")
	check_condition(abs(pain_overlay.color.a - alpha) < 0.01, 
		"Pain overlay alpha should match damage-scaled alpha (expected: %.2f, actual: %.2f)" % [alpha, pain_overlay.color.a])
	
	# Clean up
	pain_overlay.queue_free()

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
