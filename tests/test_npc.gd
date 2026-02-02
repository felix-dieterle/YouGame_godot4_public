extends Node
# Test script for NPC state machine and behavior

const NPC = preload("res://scripts/systems/character/npc.gd")

var test_results: Array = []
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n=== NPC SYSTEM TEST ===")
	
	# Run tests
	test_npc_creation()
	test_state_machine_initialization()
	test_idle_to_walk_transition()
	test_walk_movement()
	test_random_walk_direction()
	
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

func test_npc_creation() -> void:
	test_count += 1
	var test_name = "NPC can be instantiated"
	
	var npc = NPC.new()
	
	if npc != null and npc is CharacterBody3D:
		pass_test(test_name)
	else:
		fail_test(test_name, "NPC failed to instantiate or is wrong type")
	
	npc.free()

func test_state_machine_initialization() -> void:
	test_count += 1
	var test_name = "NPC state machine initializes correctly"
	
	# Create test scene
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	var npc = NPC.new()
	test_scene.add_child(npc)
	
	# Wait for ready
	await get_tree().process_frame
	
	# Check initial state
	var initial_state = npc.current_state
	var has_timer = npc.state_timer > 0
	
	test_scene.queue_free()
	
	if initial_state == NPC.State.IDLE and has_timer:
		pass_test(test_name)
	else:
		fail_test(test_name, "Initial state not IDLE or timer not set")

func test_idle_to_walk_transition() -> void:
	test_count += 1
	var test_name = "NPC transitions from IDLE to WALK"
	
	# Create test scene
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	var npc = NPC.new()
	test_scene.add_child(npc)
	
	# Wait for ready
	await get_tree().process_frame
	
	# Force transition to WALK
	npc._transition_to_state(NPC.State.WALK)
	
	# Check state changed
	var is_walking = npc.current_state == NPC.State.WALK
	var has_direction = npc.walk_direction.length() > 0.0
	var has_timer = npc.state_timer > 0
	
	test_scene.queue_free()
	
	if is_walking and has_direction and has_timer:
		pass_test(test_name)
	else:
		fail_test(test_name, "State transition failed or properties not set correctly")

func test_walk_movement() -> void:
	test_count += 1
	var test_name = "NPC moves when in WALK state"
	
	# Create test scene
	var test_scene = Node3D.new()
	add_child(test_scene)
	
	var npc = NPC.new()
	npc.position = Vector3(0, 0, 0)
	test_scene.add_child(npc)
	
	# Wait for ready
	await get_tree().process_frame
	
	# Set to walk state
	npc._transition_to_state(NPC.State.WALK)
	var initial_pos = npc.position
	
	# Simulate some physics frames
	for i in range(10):
		npc._physics_process(0.016)  # ~60 FPS
		await get_tree().process_frame
	
	var final_pos = npc.position
	var moved = initial_pos.distance_to(final_pos) > 0.1
	
	test_scene.queue_free()
	
	if moved:
		pass_test(test_name)
	else:
		fail_test(test_name, "NPC did not move during WALK state")

func test_random_walk_direction() -> void:
	test_count += 1
	var test_name = "NPC walk directions are random"
	
	# Create multiple NPCs and check their walk directions differ
	var directions = []
	
	for i in range(5):
		var npc = NPC.new()
		npc._transition_to_state(NPC.State.WALK)
		directions.append(npc.walk_direction)
		npc.free()
	
	# Check that not all directions are the same
	var all_same = true
	var first_dir = directions[0]
	for dir in directions:
		if dir.distance_to(first_dir) > 0.1:
			all_same = false
			break
	
	if not all_same:
		pass_test(test_name)
	else:
		fail_test(test_name, "All NPC walk directions are identical (should be random)")

# Helper functions

func pass_test(test_name: String, message: String = "") -> void:
	passed_count += 1
	print("✓ PASS: ", test_name)
	if message != "":
		print("  ", message)

func fail_test(test_name: String, message: String) -> void:
	print("✗ FAIL: ", test_name)
	print("  ", message)
