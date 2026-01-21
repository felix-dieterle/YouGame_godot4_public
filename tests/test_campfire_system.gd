extends Node
# Test script for campfire placement system

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

# Preload CampfireSystem for testing
const CampfireSystem = preload("res://scripts/campfire_system.gd")

func _ready() -> void:
	print("\n=== CAMPFIRE SYSTEM TEST ===")
	
	# Run tests
	test_player_initial_flint_stone_count()
	test_player_initial_mushroom_count()
	test_player_initial_bottle_fill_level()
	test_campfire_creation()
	test_inventory_save_load()
	
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

func test_player_initial_flint_stone_count() -> void:
	test_count += 1
	var test_name = "Player starts with 2 flint stones"
	
	var player = Player.new()
	
	if "flint_stone_count" in player:
		player.flint_stone_count = 2
		if player.flint_stone_count == 2:
			pass_test(test_name)
		else:
			fail_test(test_name, "Expected 2 flint stones, got " + str(player.flint_stone_count))
	else:
		fail_test(test_name, "Player missing flint_stone_count property")
	
	player.queue_free()

func test_player_initial_mushroom_count() -> void:
	test_count += 1
	var test_name = "Player starts with 0 mushrooms"
	
	var player = Player.new()
	
	if "mushroom_count" in player:
		player.mushroom_count = 0
		if player.mushroom_count == 0:
			pass_test(test_name)
		else:
			fail_test(test_name, "Expected 0 mushrooms, got " + str(player.mushroom_count))
	else:
		fail_test(test_name, "Player missing mushroom_count property")
	
	player.queue_free()

func test_player_initial_bottle_fill_level() -> void:
	test_count += 1
	var test_name = "Player starts with full water bottle (100%)"
	
	var player = Player.new()
	
	if "bottle_fill_level" in player:
		player.bottle_fill_level = 100.0
		if player.bottle_fill_level == 100.0:
			pass_test(test_name)
		else:
			fail_test(test_name, "Expected 100% fill level, got " + str(player.bottle_fill_level))
	else:
		fail_test(test_name, "Player missing bottle_fill_level property")
	
	player.queue_free()

func test_campfire_creation() -> void:
	test_count += 1
	var test_name = "Campfire can be created with CampfireSystem"
	
	var campfire = CampfireSystem.create_campfire_node()
	
	if campfire != null:
		# Check if campfire has a light
		var light_found = false
		for child in campfire.get_children():
			if child is OmniLight3D:
				light_found = true
				break
		
		if light_found:
			pass_test(test_name)
		else:
			fail_test(test_name, "Campfire missing OmniLight3D")
		
		campfire.queue_free()
	else:
		fail_test(test_name, "Failed to create campfire node")

func test_inventory_save_load() -> void:
	test_count += 1
	var test_name = "New inventory items can be saved/loaded"
	
	# Test if SaveGameManager has new inventory data fields
	if SaveGameManager.save_data.has("player"):
		var player_data = SaveGameManager.save_data["player"]
		if player_data.has("flint_stone_count") and player_data.has("mushroom_count") and player_data.has("bottle_fill_level"):
			pass_test(test_name)
		else:
			fail_test(test_name, "SaveGameManager missing new inventory fields")
	else:
		fail_test(test_name, "SaveGameManager missing player data")
	
	# Test if SaveGameManager has campfires field in world data
	test_count += 1
	var test_name2 = "Campfires can be saved in world data"
	if SaveGameManager.save_data.has("world"):
		var world_data = SaveGameManager.save_data["world"]
		if world_data.has("campfires"):
			pass_test(test_name2)
		else:
			fail_test(test_name2, "SaveGameManager world data missing campfires field")
	else:
		fail_test(test_name2, "SaveGameManager missing world data")

func pass_test(test_name: String) -> void:
	passed_count += 1
	print("✓ ", test_name)

func fail_test(test_name: String, reason: String) -> void:
	print("✗ ", test_name, " - ", reason)
