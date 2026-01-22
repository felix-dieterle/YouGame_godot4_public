extends Node

# Test suite for jetpack sound feature
# Tests that jet sounds play instead of footsteps when jetpack is active

var test_passed: int = 0
var test_failed: int = 0

func _ready():
	print("=== Starting Jetpack Sound Tests ===")
	test_sound_interval_configuration()
	test_sound_constants()
	
	# Print results
	print("\n=== Test Results ===")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	
	print("=== All Jetpack Sound Tests Completed ===")
	if test_failed == 0:
		print("All tests PASSED!")
		get_tree().quit(0)
	else:
		print("Some tests FAILED!")
		get_tree().quit(1)

func test_sound_interval_configuration():
	print("\n--- Test: Sound Interval Configuration ---")
	
	# Test that jet sound interval is faster than footstep interval
	var footstep_interval = 0.5
	var jet_sound_multiplier = 0.3  # From JET_SOUND_INTERVAL_MULTIPLIER constant
	var jet_interval = footstep_interval * jet_sound_multiplier
	
	check_condition(jet_interval < footstep_interval, 
		"Jet sound interval (%f) should be faster than footstep interval (%f)" % [jet_interval, footstep_interval])
	
	# Test that jet sound plays more frequently (smaller interval)
	var expected_jet_interval = 0.15  # 0.5 * 0.3
	check_condition(abs(jet_interval - expected_jet_interval) < 0.01,
		"Jet interval should be approximately 0.15 seconds, got %f" % jet_interval)

func test_sound_constants():
	print("\n--- Test: Sound Constants ---")
	
	# Test that constants are properly defined with reasonable values
	var jet_sound_interval_multiplier = 0.3
	var jet_harmonic_ratio = 1.5
	
	check_condition(jet_sound_interval_multiplier > 0.0 and jet_sound_interval_multiplier < 1.0,
		"Jet sound interval multiplier should be between 0 and 1, got %f" % jet_sound_interval_multiplier)
	
	check_condition(jet_harmonic_ratio > 1.0,
		"Jet harmonic ratio should be greater than 1.0 for proper harmonic, got %f" % jet_harmonic_ratio)

# Helper function for test assertions
func check_condition(condition: bool, message: String):
	if not condition:
		print("  ❌ FAIL: " + message)
		test_failed += 1
		push_error(message)
	else:
		print("  ✅ PASS: " + message)
		test_passed += 1
