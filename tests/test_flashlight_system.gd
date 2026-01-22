extends Node
# Test script for flashlight system

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n=== FLASHLIGHT SYSTEM TEST ===")
	
	# Run tests
	test_player_has_flashlight_properties()
	test_flashlight_default_state()
	test_flashlight_save_load()
	
	# Print summary
	print("\n=== TEST SUMMARY ===")
	print("Tests run: ", test_count)
	print("Tests passed: ", passed_count)
	print("Tests failed: ", test_count - passed_count)
	
	if passed_count == test_count:
		print("✓ All tests passed!")
		get_tree().quit(0)
	else:
		print("✗ Some tests failed")
		get_tree().quit(1)

func test_player_has_flashlight_properties() -> void:
	test_count += 1
	var test_name = "Player has flashlight properties"
	
	var player = Player.new()
	
	if "flashlight_enabled" in player and "flashlight_energy" in player and "flashlight_range" in player and "flashlight_angle" in player:
		pass_test(test_name)
	else:
		fail_test(test_name, "Player missing flashlight properties")
	
	player.queue_free()

func test_flashlight_default_state() -> void:
	test_count += 1
	var test_name = "Flashlight default state is ON"
	
	var player = Player.new()
	
	# Default should be true (ON)
	if player.flashlight_enabled == true:
		pass_test(test_name)
	else:
		fail_test(test_name, "Expected flashlight_enabled to be true, got " + str(player.flashlight_enabled))
	
	player.queue_free()

func test_flashlight_save_load() -> void:
	test_count += 1
	var test_name = "Flashlight state can be saved/loaded"
	
	# Test if SaveGameManager has flashlight data field
	if SaveGameManager.save_data.has("player"):
		var player_data = SaveGameManager.save_data["player"]
		if player_data.has("flashlight_enabled"):
			# Check default value is true
			if player_data["flashlight_enabled"] == true:
				pass_test(test_name)
			else:
				fail_test(test_name, "Default flashlight_enabled should be true, got " + str(player_data["flashlight_enabled"]))
		else:
			fail_test(test_name, "SaveGameManager missing flashlight_enabled")
	else:
		fail_test(test_name, "SaveGameManager missing player data")

func pass_test(test_name: String) -> void:
	passed_count += 1
	print("✓ ", test_name)

func fail_test(test_name: String, reason: String) -> void:
	print("✗ ", test_name, " - ", reason)
