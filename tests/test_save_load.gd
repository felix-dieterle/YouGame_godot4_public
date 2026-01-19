extends Node

# Test for Save/Load Game functionality

var test_passed = true
var test_messages = []

func _ready():
    print("\n=== Save/Load Game Test ===\n")
    run_tests()
    print_results()
    
    # Exit after tests
    await get_tree().create_timer(0.5).timeout
    get_tree().quit(0 if test_passed else 1)

func run_tests():
    test_save_game_manager_exists()
    test_save_and_load_player_data()
    test_save_and_load_world_data()
    test_save_and_load_day_night_data()
    test_save_and_load_inventory_data()
    test_delete_save_file()

func test_save_game_manager_exists():
    var test_name = "SaveGameManager exists as autoload"
    if SaveGameManager != null:
        add_test_result(test_name, true, "SaveGameManager autoload is accessible")
    else:
        add_test_result(test_name, false, "SaveGameManager autoload not found")

func test_save_and_load_player_data():
    var test_name = "Save and load player data"
    
    # Clean up any existing save
    SaveGameManager.delete_save()
    
    # Update player data
    var test_position = Vector3(10.5, 2.0, -5.3)
    var test_rotation = 1.57
    var test_first_person = true
    
    SaveGameManager.update_player_data(test_position, test_rotation, test_first_person)
    
    # Save
    var save_success = SaveGameManager.save_game()
    if not save_success:
        add_test_result(test_name, false, "Failed to save game")
        return
    
    # Reset data
    SaveGameManager.save_data["player"]["position"] = Vector3.ZERO
    SaveGameManager.save_data["player"]["rotation_y"] = 0.0
    SaveGameManager.save_data["player"]["is_first_person"] = false
    
    # Load
    var load_success = SaveGameManager.load_game()
    if not load_success:
        add_test_result(test_name, false, "Failed to load game")
        return
    
    # Verify data
    var player_data = SaveGameManager.get_player_data()
    var position_match = player_data["position"].is_equal_approx(test_position)
    var rotation_match = abs(player_data["rotation_y"] - test_rotation) < 0.001
    var first_person_match = player_data["is_first_person"] == test_first_person
    
    if position_match and rotation_match and first_person_match:
        add_test_result(test_name, true, "Player data saved and loaded correctly")
    else:
        add_test_result(test_name, false, 
            "Player data mismatch - Pos: %s, Rot: %s, FP: %s" % [position_match, rotation_match, first_person_match])

func test_save_and_load_world_data():
    var test_name = "Save and load world data"
    
    # Update world data
    var test_seed = 54321
    var test_chunk = Vector2i(5, -3)
    
    SaveGameManager.update_world_data(test_seed, test_chunk)
    
    # Save
    var save_success = SaveGameManager.save_game()
    if not save_success:
        add_test_result(test_name, false, "Failed to save game")
        return
    
    # Reset data
    SaveGameManager.save_data["world"]["seed"] = 0
    SaveGameManager.save_data["world"]["player_chunk"] = Vector2i.ZERO
    
    # Load
    var load_success = SaveGameManager.load_game()
    if not load_success:
        add_test_result(test_name, false, "Failed to load game")
        return
    
    # Verify data
    var world_data = SaveGameManager.get_world_data()
    var seed_match = world_data["seed"] == test_seed
    var chunk_match = world_data["player_chunk"] == test_chunk
    
    if seed_match and chunk_match:
        add_test_result(test_name, true, "World data saved and loaded correctly")
    else:
        add_test_result(test_name, false, 
            "World data mismatch - Seed: %s, Chunk: %s" % [seed_match, chunk_match])

func test_save_and_load_day_night_data():
    var test_name = "Save and load day/night data"
    
    # Update day/night data
    var test_time = 1234.56
    var test_locked = true
    var test_lockout = 9876543.21
    var test_time_scale = 4.0
    
    SaveGameManager.update_day_night_data(test_time, test_locked, test_lockout, test_time_scale)
    
    # Save
    var save_success = SaveGameManager.save_game()
    if not save_success:
        add_test_result(test_name, false, "Failed to save game")
        return
    
    # Reset data
    SaveGameManager.save_data["day_night"]["current_time"] = 0.0
    SaveGameManager.save_data["day_night"]["is_locked_out"] = false
    SaveGameManager.save_data["day_night"]["lockout_end_time"] = 0.0
    SaveGameManager.save_data["day_night"]["time_scale"] = 1.0
    
    # Load
    var load_success = SaveGameManager.load_game()
    if not load_success:
        add_test_result(test_name, false, "Failed to load game")
        return
    
    # Verify data
    var day_night_data = SaveGameManager.get_day_night_data()
    var time_match = abs(day_night_data["current_time"] - test_time) < 0.001
    var locked_match = day_night_data["is_locked_out"] == test_locked
    var lockout_match = abs(day_night_data["lockout_end_time"] - test_lockout) < 0.001
    var time_scale_match = abs(day_night_data["time_scale"] - test_time_scale) < 0.001
    
    if time_match and locked_match and lockout_match and time_scale_match:
        add_test_result(test_name, true, "Day/night data saved and loaded correctly")
    else:
        add_test_result(test_name, false, 
            "Day/night data mismatch - Time: %s, Locked: %s, Lockout: %s, TimeScale: %s" % [time_match, locked_match, lockout_match, time_scale_match])

func test_save_and_load_inventory_data():
    var test_name = "Save and load inventory data"
    
    # Clean up any existing save to start fresh
    SaveGameManager.delete_save()
    SaveGameManager.reset_loaded_flag()
    
    # Create test inventory
    var test_inventory = {
        0: 5,  # CrystalType.RED
        1: 3,  # CrystalType.BLUE
        2: 7,  # CrystalType.GREEN
        3: 2   # CrystalType.YELLOW
    }
    
    # Update player data with inventory
    var test_position = Vector3(1.0, 2.0, 3.0)
    var test_rotation = 0.5
    var test_first_person = false
    
    SaveGameManager.update_player_data(test_position, test_rotation, test_first_person, test_inventory)
    
    # Save
    var save_success = SaveGameManager.save_game()
    if not save_success:
        add_test_result(test_name, false, "Failed to save game")
        return
    
    # Reset data
    SaveGameManager.save_data["player"]["inventory"] = {}
    SaveGameManager.reset_loaded_flag()
    
    # Load
    var load_success = SaveGameManager.load_game()
    if not load_success:
        add_test_result(test_name, false, "Failed to load game")
        return
    
    # Verify inventory data
    var player_data = SaveGameManager.get_player_data()
    var inventory = player_data.get("inventory", {})
    
    var inventory_match = inventory.size() == test_inventory.size()
    if inventory_match:
        for crystal_type in test_inventory:
            # JSON keys are strings
            if not inventory.has(str(crystal_type)) or inventory[str(crystal_type)] != test_inventory[crystal_type]:
                inventory_match = false
                break
    
    if inventory_match:
        add_test_result(test_name, true, "Inventory data saved and loaded correctly")
    else:
        add_test_result(test_name, false, 
            "Inventory data mismatch - Expected: %s, Got: %s" % [test_inventory, inventory])

func test_delete_save_file():
    var test_name = "Delete save file"
    
    # Ensure a save exists
    SaveGameManager.save_game()
    
    if not SaveGameManager.has_save_file():
        add_test_result(test_name, false, "Save file doesn't exist before delete")
        return
    
    # Delete
    var delete_success = SaveGameManager.delete_save()
    if not delete_success:
        add_test_result(test_name, false, "Failed to delete save file")
        return
    
    # Verify deleted
    if not SaveGameManager.has_save_file():
        add_test_result(test_name, true, "Save file deleted successfully")
    else:
        add_test_result(test_name, false, "Save file still exists after delete")

func add_test_result(test_name: String, passed: bool, message: String):
    test_passed = test_passed and passed
    var status = "✓ PASS" if passed else "✗ FAIL"
    var color = "green" if passed else "red"
    test_messages.append({
        "status": status,
        "name": test_name,
        "message": message,
        "color": color
    })

func print_results():
    print("\n--- Test Results ---\n")
    for result in test_messages:
        print("[%s] %s: %s" % [result.status, result.name, result.message])
    
    print("\n--- Summary ---")
    if test_passed:
        print("All tests PASSED ✓")
    else:
        print("Some tests FAILED ✗")
    print("")
