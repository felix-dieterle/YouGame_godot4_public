extends GutTest

# Test player input is disabled when loading during night lockout
# This test verifies the fix for "Problem laden nach Neustart während schlafenszeit"

var player: CharacterBody3D
var save_manager: Node

func before_each():
	# Get SaveGameManager singleton
	save_manager = get_node("/root/SaveGameManager")
	assert_not_null(save_manager, "SaveGameManager should be available")

func after_each():
	# Clean up save file
	if save_manager and save_manager.has_method("delete_save"):
		save_manager.delete_save()
	if save_manager and save_manager.has_method("reset_loaded_flag"):
		save_manager.reset_loaded_flag()
	
	if player:
		player.queue_free()
		player = null

func test_player_input_disabled_when_loading_during_lockout():
	# GIVEN: A save file with active night lockout
	var future_lockout_end = Time.get_unix_time_from_system() + 60.0  # 60 seconds in future
	save_manager.update_day_night_data(
		0.0,  # current_time
		true,  # is_locked_out
		future_lockout_end,  # lockout_end_time
		2.0,  # time_scale
		1,  # day_count
		Time.get_unix_time_from_system()  # night_start_time
	)
	save_manager.update_player_data(
		Vector3(10, 5, 10),  # position
		0.0,  # rotation_y
		false,  # is_first_person
		{},  # inventory
		100,  # torch_count
		"torch",  # selected_item
		100.0,  # current_air
		100.0,  # current_health
		2,  # flint_stone_count
		0,  # mushroom_count
		100.0,  # bottle_fill_level
		true  # flashlight_enabled
	)
	save_manager.save_game()
	
	# Reset the loaded flag so we can test loading again
	save_manager.reset_loaded_flag()
	
	# WHEN: We load the game state with player
	# Load the game data first (simulating game restart)
	save_manager.load_game()
	
	# Create a player instance (like what happens in main.tscn)
	var player_scene = load("res://scripts/player.gd")
	player = CharacterBody3D.new()
	player.set_script(player_scene)
	add_child(player)
	
	# Wait for player to initialize (simulate _ready being called)
	await wait_frames(2)
	
	# THEN: Player input should be disabled
	assert_false(player.input_enabled, "Player input should be disabled when loading during active lockout")
	assert_eq(player.global_position, Vector3(10, 5, 10), "Player position should be restored from save")

func test_player_input_enabled_when_loading_after_lockout_expires():
	# GIVEN: A save file with expired night lockout
	var past_lockout_end = Time.get_unix_time_from_system() - 100.0  # 100 seconds in past
	save_manager.update_day_night_data(
		0.0,  # current_time
		true,  # is_locked_out (but expired)
		past_lockout_end,  # lockout_end_time (in the past)
		2.0,  # time_scale
		1,  # day_count
		Time.get_unix_time_from_system() - 3700.0  # night_start_time (past)
	)
	save_manager.update_player_data(
		Vector3(20, 5, 20),  # position
		0.0,  # rotation_y
		false,  # is_first_person
		{},  # inventory
		100,  # torch_count
		"torch",  # selected_item
		100.0,  # current_air
		100.0,  # current_health
		2,  # flint_stone_count
		0,  # mushroom_count
		100.0,  # bottle_fill_level
		true  # flashlight_enabled
	)
	save_manager.save_game()
	
	# Reset the loaded flag
	save_manager.reset_loaded_flag()
	
	# WHEN: We load the game state with player
	save_manager.load_game()
	
	# Create a player instance
	var player_scene = load("res://scripts/player.gd")
	player = CharacterBody3D.new()
	player.set_script(player_scene)
	add_child(player)
	
	# Wait for player to initialize
	await wait_frames(2)
	
	# THEN: Player input should be enabled (lockout expired)
	assert_true(player.input_enabled, "Player input should be enabled when lockout has expired")
	assert_eq(player.global_position, Vector3(20, 5, 20), "Player position should be restored from save")

func test_player_input_enabled_when_no_lockout():
	# GIVEN: A save file with no lockout
	save_manager.update_day_night_data(
		1000.0,  # current_time (mid-day)
		false,  # is_locked_out
		0.0,  # lockout_end_time
		2.0,  # time_scale
		1,  # day_count
		0.0  # night_start_time
	)
	save_manager.update_player_data(
		Vector3(30, 5, 30),  # position
		0.0,  # rotation_y
		false,  # is_first_person
		{},  # inventory
		100,  # torch_count
		"torch",  # selected_item
		100.0,  # current_air
		100.0,  # current_health
		2,  # flint_stone_count
		0,  # mushroom_count
		100.0,  # bottle_fill_level
		true  # flashlight_enabled
	)
	save_manager.save_game()
	
	# Reset the loaded flag
	save_manager.reset_loaded_flag()
	
	# WHEN: We load the game state with player
	save_manager.load_game()
	
	# Create a player instance
	var player_scene = load("res://scripts/player.gd")
	player = CharacterBody3D.new()
	player.set_script(player_scene)
	add_child(player)
	
	# Wait for player to initialize
	await wait_frames(2)
	
	# THEN: Player input should be enabled (no lockout)
	assert_true(player.input_enabled, "Player input should be enabled when not in lockout")
	assert_eq(player.global_position, Vector3(30, 5, 30), "Player position should be restored from save")
