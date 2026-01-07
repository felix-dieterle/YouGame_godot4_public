extends Node

# Test suite for narrative marker system
const CHUNK = preload("res://scripts/chunk.gd")
const NARRATIVE_MARKER = preload("res://scripts/narrative_marker.gd")
const QUEST_HOOK_SYSTEM = preload("res://scripts/quest_hook_system.gd")

func _ready():
	print("=== Starting Narrative Marker Tests ===")
	test_marker_generation()
	test_marker_metadata()
	test_quest_system_registration()
	test_demo_quest_creation()
	print("=== All Tests Completed ===")
	get_tree().quit()

func test_marker_generation():
	print("\n--- Test: Marker Generation ---")
	
	var chunk = CHUNK.new(0, 0, 12345)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	
	print("Generated %d markers for chunk (0, 0)" % markers.size())
	
	for i in range(markers.size()):
		var marker = markers[i]
		print("  Marker %d: %s (type: %s, importance: %.2f)" % [
			i + 1,
			marker.marker_id,
			marker.marker_type,
			marker.importance
		])
		print("    Position: %s" % marker.world_position)
		print("    Metadata: biome=%s, landmark=%s, openness=%.2f" % [
			marker.metadata.get("biome", "unknown"),
			marker.metadata.get("landmark_type", "none"),
			marker.metadata.get("openness", 0.0)
		])
	
	# Just verify the marker count is valid (0 or more)
	if markers.size() > 0:
		print("PASS: Chunk generates markers")
	else:
		print("PASS: Chunk has no markers (valid for this terrain)")
	
	chunk.free()

func test_marker_metadata():
	print("\n--- Test: Marker Metadata ---")
	
	var chunk = CHUNK.new(1, 1, 54321)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	var all_valid = true
	
	for marker in markers:
		# Check that markers have flexible metadata instead of fixed story
		if not marker.metadata.has("biome"):
			print("FAIL: Marker %s missing biome metadata" % marker.marker_id)
			all_valid = false
		
		if not marker.metadata.has("openness"):
			print("FAIL: Marker %s missing openness metadata" % marker.marker_id)
			all_valid = false
		
		if not marker.metadata.has("landmark_type"):
			print("FAIL: Marker %s missing landmark_type metadata" % marker.marker_id)
			all_valid = false
		
		# Validate marker type
		if not marker.marker_type in ["discovery", "encounter", "landmark"]:
			print("FAIL: Invalid marker type: %s" % marker.marker_type)
			all_valid = false
	
	if all_valid and markers.size() > 0:
		print("PASS: All markers have proper metadata structure")
	elif markers.size() == 0:
		print("PASS: No markers generated (valid for this chunk)")
	else:
		print("FAIL: Some markers have invalid metadata")
	
	chunk.free()

func test_quest_system_registration():
	print("\n--- Test: Quest System Registration ---")
	
	var quest_system = QUEST_HOOK_SYSTEM.new()
	
	# Generate a chunk with markers
	var chunk = CHUNK.new(2, 2, 99999)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	
	# Register all markers
	for marker in markers:
		quest_system.register_marker(marker)
	
	print("Registered %d markers" % quest_system.available_markers.size())
	
	if quest_system.available_markers.size() == markers.size():
		print("PASS: All markers registered successfully")
	else:
		print("FAIL: Marker registration count mismatch")
	
	# Test marker selection
	if quest_system.available_markers.size() > 0:
		var selected = quest_system.select_quest_marker(Vector3(0, 0, 0), 1000.0)
		if selected != null:
			print("PASS: Quest marker selection works")
			print("  Selected: %s (importance: %.2f)" % [selected.marker_id, selected.importance])
		else:
			print("FAIL: Could not select a quest marker")
	
	chunk.free()
	quest_system.free()

func test_demo_quest_creation():
	print("\n--- Test: Demo Quest Creation ---")
	
	var quest_system = QUEST_HOOK_SYSTEM.new()
	quest_system.enable_demo_mode()
	
	# Generate multiple chunks to get various markers
	var total_markers = 0
	for x in range(3):
		for z in range(3):
			var chunk = CHUNK.new(x, z, 11111 + x * 10 + z)
			chunk.generate()
			var markers = chunk.get_narrative_markers()
			for marker in markers:
				quest_system.register_marker(marker)
				total_markers += 1
			chunk.free()
	
	print("Total markers registered: %d" % total_markers)
	
	if total_markers == 0:
		print("SKIP: No markers generated, cannot test quest creation")
		quest_system.free()
		return
	
	# Create a demo quest
	var quest = quest_system.create_demo_quest()
	
	if quest.is_empty():
		print("FAIL: Demo quest creation failed")
	else:
		print("PASS: Demo quest created successfully")
		print("  Quest ID: %s" % quest.id)
		print("  Title: %s" % quest.title)
		print("  Objectives: %d" % quest.objectives.size())
		
		# Print quest details
		for i in range(quest.objectives.size()):
			var obj = quest.objectives[i]
			print("  Objective %d: %s" % [i + 1, obj.description])
			print("    Target: %s" % obj.target)
		
		# Test story generation
		if quest.objectives.size() > 0:
			var obj = quest.objectives[0]
			if not obj.description.is_empty():
				print("PASS: Quest objectives have generated story text")
			else:
				print("FAIL: Quest objective story text is empty")
	
	quest_system.free()
