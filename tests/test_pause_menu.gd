extends Node

# Test suite for pause menu and improved settings

func _ready():
	print("=== Starting Pause Menu and Settings Tests ===")
	test_pause_menu_exists()
	test_player_group()
	test_pause_input_action()
	print("=== All Pause Menu and Settings Tests Completed ===")
	get_tree().quit()

func test_pause_menu_exists():
	print("\n--- Test: PauseMenu Script Exists ---")
	
	# Verify the pause menu script can be loaded
	var pause_menu_script = load("res://scripts/pause_menu.gd")
	if pause_menu_script:
		print("  PASS: PauseMenu script loaded successfully")
		
		# Create an instance to verify it extends Control
		var pause_menu = pause_menu_script.new()
		if pause_menu is Control:
			print("  PASS: PauseMenu extends Control")
		else:
			print("  FAIL: PauseMenu should extend Control")
		
		# Check for required methods
		if pause_menu.has_method("toggle_pause"):
			print("  PASS: PauseMenu has toggle_pause method")
		else:
			print("  FAIL: PauseMenu missing toggle_pause method")
		
		pause_menu.free()
	else:
		print("  FAIL: Could not load PauseMenu script")

func test_player_group():
	print("\n--- Test: Player Group Setup ---")
	
	# Load and instantiate player
	var player_script = load("res://scripts/player.gd")
	if player_script:
		var player = CharacterBody3D.new()
		player.set_script(player_script)
		
		# Add to tree so _ready gets called
		add_child(player)
		await get_tree().process_frame
		
		# Check if player is in the Player group
		if player.is_in_group("Player"):
			print("  PASS: Player is added to 'Player' group")
		else:
			print("  FAIL: Player should be in 'Player' group")
		
		player.queue_free()
	else:
		print("  FAIL: Could not load Player script")

func test_pause_input_action():
	print("\n--- Test: Pause Input Action ---")
	
	# Check if toggle_pause action exists in input map
	if InputMap.has_action("toggle_pause"):
		print("  PASS: toggle_pause action exists in InputMap")
		
		# Get the action's events
		var events = InputMap.action_get_events("toggle_pause")
		if events.size() > 0:
			print("  PASS: toggle_pause has input events configured")
			for event in events:
				if event is InputEventKey:
					print("    Bound to key: %s (scancode: %d)" % [event.as_text(), event.physical_keycode])
		else:
			print("  FAIL: toggle_pause has no input events")
	else:
		print("  FAIL: toggle_pause action not found in InputMap")

func test_mobile_controls_improvements():
	print("\n--- Test: Mobile Controls Improvements ---")
	
	var mobile_controls_script = load("res://scripts/mobile_controls.gd")
	if mobile_controls_script:
		var mobile_controls = Control.new()
		mobile_controls.set_script(mobile_controls_script)
		
		# Check for new methods
		if mobile_controls.has_method("_on_volume_changed"):
			print("  PASS: Mobile controls has volume control method")
		else:
			print("  FAIL: Mobile controls missing volume control method")
		
		if mobile_controls.has_method("_on_pause_game_pressed"):
			print("  PASS: Mobile controls has pause game method")
		else:
			print("  FAIL: Mobile controls missing pause game method")
		
		mobile_controls.free()
	else:
		print("  FAIL: Could not load MobileControls script")
