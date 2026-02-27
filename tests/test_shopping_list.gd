extends Node
## Tests for the ShoppingListManager system
##
## Tests:
## - Local item add / toggle / remove
## - Filtering (unchecked, checked)
## - Sorted item retrieval
## - Input validation helpers
## - ID generation format

const ShoppingListManager = preload("res://scripts/systems/shopping_list.gd")

var test_results: Array = []

func _ready() -> void:
	print("\n========================================")
	print("Shopping List Manager Tests")
	print("========================================\n")

	run_tests()
	print_results()

	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if _all_passed() else 1)

func run_tests() -> void:
	test_add_item_local()
	test_toggle_item_local()
	test_remove_item_local()
	test_clear_local()
	test_get_unchecked_items()
	test_get_checked_items()
	test_get_items_sorted()
	test_id_format()
	test_list_updated_signal()
	test_remote_not_ready_without_url()

# ---------------------------------------------------------------------------
# Individual tests
# ---------------------------------------------------------------------------

func test_add_item_local() -> void:
	print("Test: add_item_local")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var item := mgr.add_item_local("Bread")
	var ok := (
		item.has("id") and
		item["name"] == "Bread" and
		item["checked"] == false and
		mgr.items.size() == 1
	)
	_record("add_item_local creates item with correct fields", ok)

	mgr.queue_free()

func test_toggle_item_local() -> void:
	print("Test: toggle_item_local")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var item := mgr.add_item_local("Milk")
	var toggled := mgr.toggle_item_local(item["id"])
	var checked_after_toggle := mgr.items[0]["checked"]
	var untoggled := mgr.toggle_item_local(item["id"])
	var unchecked_after_untoggle := not mgr.items[0]["checked"]

	_record("toggle_item_local returns true", toggled and untoggled)
	_record("toggle_item_local flips checked state", checked_after_toggle and unchecked_after_untoggle)
	_record("toggle_item_local returns false for unknown id", not mgr.toggle_item_local("unknown"))

	mgr.queue_free()

func test_remove_item_local() -> void:
	print("Test: remove_item_local")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var item := mgr.add_item_local("Eggs")
	var removed := mgr.remove_item_local(item["id"])
	_record("remove_item_local returns true", removed)
	_record("remove_item_local empties list", mgr.items.is_empty())
	_record("remove_item_local returns false for unknown id", not mgr.remove_item_local("nope"))

	mgr.queue_free()

func test_clear_local() -> void:
	print("Test: clear_local")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	mgr.add_item_local("A")
	mgr.add_item_local("B")
	mgr.clear_local()
	_record("clear_local empties all items", mgr.items.is_empty())

	mgr.queue_free()

func test_get_unchecked_items() -> void:
	print("Test: get_unchecked_items")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var a := mgr.add_item_local("Apples")
	mgr.add_item_local("Bananas")
	mgr.toggle_item_local(a["id"])  # mark Apples as checked

	var unchecked := mgr.get_unchecked_items()
	_record("get_unchecked_items returns 1 item", unchecked.size() == 1)
	_record("get_unchecked_items returns correct item", unchecked[0]["name"] == "Bananas")

	mgr.queue_free()

func test_get_checked_items() -> void:
	print("Test: get_checked_items")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var a := mgr.add_item_local("Apples")
	mgr.add_item_local("Bananas")
	mgr.toggle_item_local(a["id"])

	var checked := mgr.get_checked_items()
	_record("get_checked_items returns 1 item", checked.size() == 1)
	_record("get_checked_items returns correct item", checked[0]["name"] == "Apples")

	mgr.queue_free()

func test_get_items_sorted() -> void:
	print("Test: get_items_sorted")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	# Manually control timestamps
	var item_b := {"id": "00000001", "name": "B", "checked": false, "created_at": 2}
	var item_a := {"id": "00000002", "name": "A", "checked": false, "created_at": 1}
	mgr.items = [item_b, item_a]

	var sorted := mgr.get_items_sorted()
	_record("get_items_sorted orders by created_at ascending",
		sorted[0]["name"] == "A" and sorted[1]["name"] == "B")

	mgr.queue_free()

func test_id_format() -> void:
	print("Test: _generate_id")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var id := mgr._generate_id()
	var is_8_hex := id.length() == 8 and id.to_lower() == id and id.is_valid_hex_number(false)
	_record("_generate_id returns 8-char hex string", is_8_hex)

	# IDs should differ between calls (with very high probability)
	var id2 := mgr._generate_id()
	_record("_generate_id produces unique values", id != id2)

	mgr.queue_free()

func test_list_updated_signal() -> void:
	print("Test: list_updated signal")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var signal_received := false
	mgr.list_updated.connect(func(_items): signal_received = true)

	mgr.add_item_local("Signal Test")
	_record("list_updated fires on add_item_local", signal_received)

	signal_received = false
	var item_id: String = mgr.items[0]["id"]
	mgr.toggle_item_local(item_id)
	_record("list_updated fires on toggle_item_local", signal_received)

	signal_received = false
	mgr.remove_item_local(item_id)
	_record("list_updated fires on remove_item_local", signal_received)

	mgr.queue_free()

func test_remote_not_ready_without_url() -> void:
	print("Test: remote actions fail gracefully without backend_url")
	var mgr := ShoppingListManager.new()
	add_child(mgr)

	var error_received := false
	mgr.request_error.connect(func(_msg): error_received = true)

	# Without backend_url set, fetch_list should emit request_error
	mgr.current_list_id = "abcd1234"
	mgr.fetch_list()
	_record("fetch_list emits request_error when backend_url is empty", error_received)

	error_received = false
	mgr.backend_url = "https://example.com/api.php"
	mgr.current_list_id = ""
	mgr.fetch_list()
	_record("fetch_list emits request_error when current_list_id is empty", error_received)

	mgr.queue_free()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _record(label: String, passed: bool) -> void:
	var status := "✓ PASS" if passed else "✗ FAIL"
	print("  [%s] %s" % [status, label])
	test_results.append(passed)

func _all_passed() -> bool:
	return test_results.all(func(r): return r)

func print_results() -> void:
	print("\n========================================")
	print("Test Results Summary")
	print("========================================")
	var passed := test_results.filter(func(r): return r).size()
	var total := test_results.size()
	print("Passed: %d/%d" % [passed, total])
	if passed == total:
		print("All tests PASSED ✓")
	else:
		print("Some tests FAILED ✗")
	print("")
