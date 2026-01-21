extends Node
# Test script for torch placement system

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

# Preload TorchSystem for testing
const TorchSystem = preload("res://scripts/torch_system.gd")

func _ready() -> void:
    print("\n=== TORCH SYSTEM TEST ===")
    
    # Run tests
    test_player_initial_torch_count()
    test_torch_creation()
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

func test_player_initial_torch_count() -> void:
    test_count += 1
    var test_name = "Player starts with 100 torches"
    
    # Check if player has the torch_count property
    var player = Player.new()
    
    if "torch_count" in player:
        if player.torch_count == 100:
            pass_test(test_name)
        else:
            fail_test(test_name, "Expected 100 torches, got " + str(player.torch_count))
    else:
        fail_test(test_name, "Player missing torch_count property")
    
    player.queue_free()

func test_torch_creation() -> void:
    test_count += 1
    var test_name = "Torch can be created with TorchSystem"
    
    var torch = TorchSystem.create_torch_node()
    
    if torch != null:
        # Check if torch has a light
        var light_found = false
        for child in torch.get_children():
            if child is OmniLight3D:
                light_found = true
                break
        
        if light_found:
            pass_test(test_name)
        else:
            fail_test(test_name, "Torch missing OmniLight3D")
        
        torch.queue_free()
    else:
        fail_test(test_name, "Failed to create torch node")

func test_inventory_save_load() -> void:
    test_count += 1
    var test_name = "Inventory data can be saved/loaded"
    
    # Test if SaveGameManager has torch data fields
    if SaveGameManager.save_data.has("player"):
        var player_data = SaveGameManager.save_data["player"]
        if player_data.has("torch_count") and player_data.has("selected_item"):
            pass_test(test_name)
        else:
            fail_test(test_name, "SaveGameManager missing torch_count or selected_item")
    else:
        fail_test(test_name, "SaveGameManager missing player data")

func pass_test(test_name: String) -> void:
    passed_count += 1
    print("✓ ", test_name)

func fail_test(test_name: String, reason: String) -> void:
    print("✗ ", test_name, " - ", reason)
