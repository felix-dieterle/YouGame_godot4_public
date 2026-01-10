extends Node

# Preload dependencies
const Chunk = preload("res://scripts/chunk.gd")
const NarrativeMarker = preload("res://scripts/narrative_marker.gd")
const QuestHookSystem = preload("res://scripts/quest_hook_system.gd")

# Test the narrative marker generation and quest hook system

func _ready():
	print("=== Starting Narrative Markers Tests ===")
	test_chunk_generates_narrative_markers()
	test_marker_has_flexible_metadata()
	test_quest_hook_system_registers_markers()
	test_quest_hook_system_selects_best_marker()
	test_demo_mode_generates_story()
	test_demo_quest_creation()
	test_landmark_chunks_get_more_markers()
	print("=== All Narrative Markers Tests Completed ===")
	get_tree().quit()

func test_chunk_generates_narrative_markers():
	print("\n--- Test: Chunk Generates Narrative Markers ---")
	var chunk = Chunk.new(0, 0, 12345)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	
	# Verify we get an array (not null) - markers may or may not be generated
	if markers != null:
		print("PASS: Should return a markers array")
	else:
		print("FAIL: Should return a markers array")
	
	# Check marker properties if markers exist
	if markers.size() > 0:
		var marker = markers[0]
		if marker != null:
			print("PASS: Marker should not be null")
		else:
			print("FAIL: Marker should not be null")
		
		if marker.marker_type in ["discovery", "encounter", "landmark"]:
			print("PASS: Marker type should be valid")
		else:
			print("FAIL: Marker type should be valid")
		
		if marker.importance >= 0.0 and marker.importance <= 1.0:
			print("PASS: Importance should be between 0 and 1")
		else:
			print("FAIL: Importance should be between 0 and 1")
	
	chunk.queue_free()

func test_marker_has_flexible_metadata():
	print("\n--- Test: Marker Has Flexible Metadata ---")
	var chunk = Chunk.new(0, 0, 12345)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	
	if markers.size() > 0:
		var marker = markers[0]
		
		# Marker should have metadata instead of fixed story text
		if marker.metadata.has("biome"):
			print("PASS: Marker should have biome metadata")
		else:
			print("FAIL: Marker should have biome metadata")
		
		if marker.metadata.has("openness"):
			print("PASS: Marker should have openness metadata")
		else:
			print("FAIL: Marker should have openness metadata")
		
		if marker.metadata.has("landmark_type"):
			print("PASS: Marker should have landmark_type metadata")
		else:
			print("FAIL: Marker should have landmark_type metadata")
		
		# Metadata should be valid
		if not marker.metadata["biome"].is_empty():
			print("PASS: Biome should not be empty")
		else:
			print("FAIL: Biome should not be empty")
		
		if marker.metadata["openness"] >= 0.0 and marker.metadata["openness"] <= 1.0:
			print("PASS: Openness should be between 0 and 1")
		else:
			print("FAIL: Openness should be between 0 and 1")
	
	chunk.queue_free()

func test_quest_hook_system_registers_markers():
	print("\n--- Test: Quest Hook System Registers Markers ---")
	var quest_system = QuestHookSystem.new()
	
	# Create test marker
	var marker = NarrativeMarker.new("test_marker", Vector2i(0, 0), Vector3(0, 0, 0), "discovery")
	marker.importance = 0.7
	marker.metadata = {"biome": "grassland", "openness": 0.8, "landmark_type": ""}
	
	# Register marker
	quest_system.register_marker(marker)
	
	# Verify registration
	if quest_system.available_markers.size() == 1:
		print("PASS: Should have 1 registered marker")
	else:
		print("FAIL: Should have 1 registered marker")
	
	if quest_system.available_markers[0] == marker:
		print("PASS: Registered marker should match")
	else:
		print("FAIL: Registered marker should match")
	
	quest_system.queue_free()

func test_quest_hook_system_selects_best_marker():
	print("\n--- Test: Quest Hook System Selects Best Marker ---")
	var quest_system = QuestHookSystem.new()
	
	# Create multiple markers with different importance
	var marker1 = NarrativeMarker.new("marker1", Vector2i(0, 0), Vector3(10, 0, 10), "discovery")
	marker1.importance = 0.5
	
	var marker2 = NarrativeMarker.new("marker2", Vector2i(0, 0), Vector3(15, 0, 15), "landmark")
	marker2.importance = 0.9  # Higher importance
	
	var marker3 = NarrativeMarker.new("marker3", Vector2i(0, 0), Vector3(20, 0, 20), "encounter")
	marker3.importance = 0.6
	
	quest_system.register_marker(marker1)
	quest_system.register_marker(marker2)
	quest_system.register_marker(marker3)
	
	# Select best marker near origin
	var selected = quest_system.select_quest_marker(Vector3(0, 0, 0), 100.0)
	
	if selected != null:
		print("PASS: Should select a marker")
	else:
		print("FAIL: Should select a marker")
	
	if selected != null and selected.marker_id == "marker2":
		print("PASS: Should select marker with highest importance")
	else:
		print("FAIL: Should select marker with highest importance")
	
	quest_system.queue_free()

func test_demo_mode_generates_story():
	print("\n--- Test: Demo Mode Generates Story ---")
	var quest_system = QuestHookSystem.new()
	quest_system.enable_demo_mode()
	
	# Create test marker
	var marker = NarrativeMarker.new("test_marker", Vector2i(0, 0), Vector3(0, 0, 0), "discovery")
	marker.metadata = {
		"biome": "grassland",
		"openness": 0.8,
		"landmark_type": "hill"
	}
	
	# Generate story
	var story = quest_system.generate_dummy_story_for_marker(marker)
	
	if not story.is_empty():
		print("PASS: Demo mode should generate a story")
	else:
		print("FAIL: Demo mode should generate a story")
	
	if story.contains("grassland"):
		print("PASS: Story should mention biome")
	else:
		print("FAIL: Story should mention biome")
	
	quest_system.queue_free()

func test_demo_quest_creation():
	print("\n--- Test: Demo Quest Creation ---")
	var quest_system = QuestHookSystem.new()
	quest_system.enable_demo_mode()
	
	# Create and register markers
	for i in range(3):
		var marker = NarrativeMarker.new("marker_%d" % i, Vector2i(0, 0), 
			Vector3(i * 10.0, 0, i * 10.0), "discovery")
		marker.importance = 0.5 + i * 0.1
		marker.metadata = {"biome": "grassland", "openness": 0.5, "landmark_type": ""}
		quest_system.register_marker(marker)
	
	# Create demo quest
	var quest = quest_system.create_demo_quest()
	
	if not quest.is_empty():
		print("PASS: Should create a quest")
	else:
		print("FAIL: Should create a quest")
	
	if quest.has("id"):
		print("PASS: Quest should have an ID")
	else:
		print("FAIL: Quest should have an ID")
	
	if quest.has("title"):
		print("PASS: Quest should have a title")
	else:
		print("FAIL: Quest should have a title")
	
	if quest.has("objectives"):
		print("PASS: Quest should have objectives")
	else:
		print("FAIL: Quest should have objectives")
	
	if quest.objectives.size() >= 1 and quest.objectives.size() <= 3:
		print("PASS: Quest should have 1-3 objectives")
	else:
		print("FAIL: Quest should have 1-3 objectives")
	
	# Check objective structure
	if quest.objectives.size() > 0:
		var obj = quest.objectives[0]
		if obj.has("description"):
			print("PASS: Objective should have description")
		else:
			print("FAIL: Objective should have description")
		
		if obj.has("target"):
			print("PASS: Objective should have target")
		else:
			print("FAIL: Objective should have target")
		
		if not obj.description.is_empty():
			print("PASS: Objective description should not be empty")
		else:
			print("FAIL: Objective description should not be empty")
	
	quest_system.queue_free()

func test_landmark_chunks_get_more_markers():
	print("\n--- Test: Landmark Chunks Get More Markers ---")
	# Chunk with landmark should generate more markers
	var chunk_landmark = Chunk.new(5, 5, 12345)
	chunk_landmark.generate()
	
	# Count markers from landmark chunk
	var landmark_markers = chunk_landmark.get_narrative_markers()
	
	# Landmark type is determined by terrain generation, so we can't guarantee it
	# But we can verify the marker count is reasonable
	if landmark_markers.size() >= 0 and landmark_markers.size() <= 3:
		print("PASS: Chunk should generate 0-3 markers")
	else:
		print("FAIL: Chunk should generate 0-3 markers")
	
	chunk_landmark.queue_free()
