extends Node
# Test script for Quest Hook System

const QuestHookSystem = preload("res://scripts/systems/quest/quest_hook_system.gd")
const NarrativeMarker = preload("res://scripts/systems/quest/narrative_marker.gd")

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n=== QUEST HOOK SYSTEM TEST ===")
	
	# Run tests
	test_quest_hook_system_creation()
	test_marker_registration()
	test_quest_creation_from_discovery_marker()
	test_quest_creation_from_encounter_marker()
	test_quest_creation_from_landmark_marker()
	test_quest_objective_completion()
	test_multiple_active_quests()
	
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

func test_quest_hook_system_creation() -> void:
	test_count += 1
	var test_name = "QuestHookSystem can be instantiated"
	
	var qhs = QuestHookSystem.new()
	
	if qhs != null and qhs.available_markers is Array and qhs.active_quests is Dictionary:
		pass_test(test_name)
	else:
		fail_test(test_name, "QuestHookSystem failed to instantiate correctly")
	
	qhs.free()

func test_marker_registration() -> void:
	test_count += 1
	var test_name = "Markers can be registered with QuestHookSystem"
	
	var qhs = QuestHookSystem.new()
	var marker = NarrativeMarker.new("test_marker", Vector2i(0, 0), Vector3(10, 0, 10), "discovery")
	
	qhs.register_marker(marker)
	
	if qhs.available_markers.size() == 1 and qhs.available_markers[0] == marker:
		pass_test(test_name)
	else:
		fail_test(test_name, "Marker not properly registered")
	
	marker.free()
	qhs.free()

func test_quest_creation_from_discovery_marker() -> void:
	test_count += 1
	var test_name = "Quest can be created from discovery marker"
	
	var qhs = QuestHookSystem.new()
	var marker = NarrativeMarker.new("discovery_marker", Vector2i(1, 1), Vector3(50, 0, 50), "discovery")
	
	qhs.register_marker(marker)
	var quest = qhs.create_quest_from_marker(marker)
	
	var valid_quest = (
		quest.has("id") and
		quest.has("marker") and
		quest.marker == marker and
		quest.has("status") and
		quest.status == "active" and
		quest.has("objectives") and
		quest.objectives.size() > 0 and
		quest.objectives[0].type == "reach_location"
	)
	
	if valid_quest:
		pass_test(test_name)
	else:
		fail_test(test_name, "Quest not created correctly from discovery marker")
	
	marker.free()
	qhs.free()

func test_quest_creation_from_encounter_marker() -> void:
	test_count += 1
	var test_name = "Quest can be created from encounter marker"
	
	var qhs = QuestHookSystem.new()
	var marker = NarrativeMarker.new("encounter_marker", Vector2i(0, 0), Vector3(25, 0, 25), "encounter")
	
	qhs.register_marker(marker)
	var quest = qhs.create_quest_from_marker(marker)
	
	var valid_quest = (
		quest.objectives.size() > 0 and
		quest.objectives[0].type == "interact"
	)
	
	if valid_quest:
		pass_test(test_name)
	else:
		fail_test(test_name, "Quest not created correctly from encounter marker")
	
	marker.free()
	qhs.free()

func test_quest_creation_from_landmark_marker() -> void:
	test_count += 1
	var test_name = "Quest can be created from landmark marker"
	
	var qhs = QuestHookSystem.new()
	var marker = NarrativeMarker.new("landmark_marker", Vector2i(3, 3), Vector3(100, 0, 100), "landmark")
	
	qhs.register_marker(marker)
	var quest = qhs.create_quest_from_marker(marker)
	
	var valid_quest = (
		quest.objectives.size() > 0 and
		quest.objectives[0].type == "explore"
	)
	
	if valid_quest:
		pass_test(test_name)
	else:
		fail_test(test_name, "Quest not created correctly from landmark marker")
	
	marker.free()
	qhs.free()

func test_quest_objective_completion() -> void:
	test_count += 1
	var test_name = "Quest objectives can be marked as completed"
	
	var qhs = QuestHookSystem.new()
	var marker = NarrativeMarker.new("completion_marker", Vector2i(0, 0), Vector3(10, 0, 10), "discovery")
	
	qhs.register_marker(marker)
	var quest = qhs.create_quest_from_marker(marker)
	var quest_id = quest.id
	
	# Mark objective as completed
	qhs.update_quest(quest_id, 0, true)
	
	var is_completed = qhs.active_quests[quest_id].objectives[0].completed
	
	if is_completed:
		pass_test(test_name)
	else:
		fail_test(test_name, "Objective not marked as completed")
	
	marker.free()
	qhs.free()

func test_multiple_active_quests() -> void:
	test_count += 1
	var test_name = "Multiple quests can be active simultaneously"
	
	var qhs = QuestHookSystem.new()
	
	# Create multiple markers and quests
	for i in range(3):
		var marker = NarrativeMarker.new("marker_%d" % i, Vector2i(i, i), Vector3(i * 10, 0, i * 10), "discovery")
		qhs.register_marker(marker)
		qhs.create_quest_from_marker(marker)
	
	if qhs.active_quests.size() == 3 and qhs.available_markers.size() == 3:
		pass_test(test_name)
	else:
		fail_test(test_name, "Failed to manage multiple active quests")
	
	# Cleanup
	for marker in qhs.available_markers:
		marker.free()
	qhs.free()

# Helper functions

func pass_test(test_name: String, message: String = "") -> void:
	passed_count += 1
	print("✓ PASS: ", test_name)
	if message != "":
		print("  ", message)

func fail_test(test_name: String, message: String) -> void:
	print("✗ FAIL: ", test_name)
	print("  ", message)
