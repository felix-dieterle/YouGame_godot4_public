extends Node
# Test for Android Widget Integration
# Verifies that the SaveGameWidgetExporter is properly configured

var test_passed = false
var test_message = ""

func _ready():
	print("=== SaveGameWidget Integration Test ===")
	
	# Test 1: Verify SaveGameWidgetExporter autoload exists
	var has_exporter = has_node("/root/SaveGameWidgetExporter")
	if not has_exporter:
		test_message = "FAIL: SaveGameWidgetExporter autoload not found"
		print(test_message)
		_finish_test(false)
		return
	
	print("✓ SaveGameWidgetExporter autoload found")
	
	# Test 2: Verify SaveGameManager integration
	var has_manager = has_node("/root/SaveGameManager")
	if not has_manager:
		test_message = "FAIL: SaveGameManager autoload not found"
		print(test_message)
		_finish_test(false)
		return
	
	print("✓ SaveGameManager autoload found")
	
	# Test 3: Test export_save_data method exists and is callable
	var exporter = get_node("/root/SaveGameWidgetExporter")
	if not exporter.has_method("export_save_data"):
		test_message = "FAIL: SaveGameWidgetExporter.export_save_data() method not found"
		print(test_message)
		_finish_test(false)
		return
	
	print("✓ export_save_data method found")
	
	# Test 4: Test clear_widget_data method exists
	if not exporter.has_method("clear_widget_data"):
		test_message = "FAIL: SaveGameWidgetExporter.clear_widget_data() method not found"
		print(test_message)
		_finish_test(false)
		return
	
	print("✓ clear_widget_data method found")
	
	# Test 5: Test calling export_save_data with mock data (should not crash)
	var mock_save_data = {
		"meta": {
			"timestamp": 1234567890
		},
		"day_night": {
			"day_count": 5
		},
		"player": {
			"current_health": 75.0,
			"torch_count": 42,
			"position": Vector3(100, 10, 200)
		}
	}
	
	exporter.export_save_data(mock_save_data)
	print("✓ export_save_data executed without error")
	
	# Test 6: Test clear_widget_data (should not crash)
	exporter.clear_widget_data()
	print("✓ clear_widget_data executed without error")
	
	# All tests passed
	test_message = "PASS: All SaveGameWidget integration tests passed"
	print(test_message)
	_finish_test(true)

func _finish_test(passed: bool):
	test_passed = passed
	if passed:
		print("\n=== TEST PASSED ===")
	else:
		print("\n=== TEST FAILED ===")
	
	# Wait a frame then quit
	await get_tree().process_frame
	get_tree().quit(0 if passed else 1)
