extends GutTest

# Test that the night overlay (sleep mode) allows mouse input to pass through
# This test verifies the fix for "'new game' Option not working when being in sleep mode"

var ui_manager: Control

func before_each():
	# Create UI manager instance
	var ui_manager_script = load("res://scripts/ui/ui_manager.gd")
	ui_manager = Control.new()
	ui_manager.set_script(ui_manager_script)
	add_child(ui_manager)
	
	# Wait for UI manager to initialize
	await wait_frames(2)

func after_each():
	if ui_manager:
		ui_manager.queue_free()
		ui_manager = null

func test_night_overlay_allows_mouse_passthrough():
	# GIVEN: UI manager is initialized
	assert_not_null(ui_manager, "UI manager should be created")
	
	# WHEN: We check the night_overlay property
	var night_overlay = ui_manager.get("night_overlay")
	assert_not_null(night_overlay, "Night overlay should exist")
	
	# THEN: The night overlay should have mouse_filter set to MOUSE_FILTER_IGNORE
	# This allows mouse events to pass through to UI elements above it (like start menu)
	assert_eq(
		night_overlay.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"Night overlay should ignore mouse input to allow clicks on start menu above it"
	)

func test_night_overlay_z_index_below_start_menu():
	# GIVEN: UI manager is initialized
	assert_not_null(ui_manager, "UI manager should be created")
	
	# WHEN: We check the night_overlay z_index
	var night_overlay = ui_manager.get("night_overlay")
	assert_not_null(night_overlay, "Night overlay should exist")
	
	# THEN: The night overlay z_index should be 200 (below start menu which is 250)
	# This ensures the start menu appears above the night overlay
	assert_eq(
		night_overlay.z_index,
		200,
		"Night overlay should have z_index 200 (below start menu at 250)"
	)
