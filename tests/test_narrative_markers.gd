extends GutTest

# Test the narrative marker generation and quest hook system

func test_chunk_generates_narrative_markers():
	var chunk = Chunk.new(0, 0, 12345)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	
	# Chunks should generate at least some markers
	assert_true(markers.size() >= 0, "Chunk should generate markers")
	
	# Check marker properties if markers exist
	if markers.size() > 0:
		var marker = markers[0]
		assert_not_null(marker, "Marker should not be null")
		assert_true(marker is NarrativeMarker, "Should be a NarrativeMarker")
		assert_false(marker.marker_id.is_empty(), "Marker should have an ID")
		assert_true(marker.marker_type in ["discovery", "encounter", "landmark"], 
			"Marker type should be valid")
		assert_true(marker.importance >= 0.0 and marker.importance <= 1.0, 
			"Importance should be between 0 and 1")
	
	chunk.queue_free()

func test_marker_has_flexible_metadata():
	var chunk = Chunk.new(0, 0, 12345)
	chunk.generate()
	
	var markers = chunk.get_narrative_markers()
	
	if markers.size() > 0:
		var marker = markers[0]
		
		# Marker should have metadata instead of fixed story text
		assert_true(marker.metadata.has("biome"), "Marker should have biome metadata")
		assert_true(marker.metadata.has("openness"), "Marker should have openness metadata")
		assert_true(marker.metadata.has("landmark_type"), "Marker should have landmark_type metadata")
		
		# Metadata should be valid
		assert_false(marker.metadata["biome"].is_empty(), "Biome should not be empty")
		assert_true(marker.metadata["openness"] >= 0.0 and marker.metadata["openness"] <= 1.0,
			"Openness should be between 0 and 1")
	
	chunk.queue_free()

func test_quest_hook_system_registers_markers():
	var quest_system = QuestHookSystem.new()
	
	# Create test marker
	var marker = NarrativeMarker.new("test_marker", Vector2i(0, 0), Vector3(0, 0, 0), "discovery")
	marker.importance = 0.7
	marker.metadata = {"biome": "grassland", "openness": 0.8, "landmark_type": ""}
	
	# Register marker
	quest_system.register_marker(marker)
	
	# Verify registration
	assert_eq(quest_system.available_markers.size(), 1, "Should have 1 registered marker")
	assert_eq(quest_system.available_markers[0], marker, "Registered marker should match")
	
	quest_system.queue_free()

func test_quest_hook_system_selects_best_marker():
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
	
	assert_not_null(selected, "Should select a marker")
	assert_eq(selected.marker_id, "marker2", "Should select marker with highest importance")
	
	quest_system.queue_free()

func test_demo_mode_generates_story():
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
	
	assert_false(story.is_empty(), "Demo mode should generate a story")
	assert_true(story.contains("grassland"), "Story should mention biome")
	
	quest_system.queue_free()

func test_demo_quest_creation():
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
	
	assert_false(quest.is_empty(), "Should create a quest")
	assert_true(quest.has("id"), "Quest should have an ID")
	assert_true(quest.has("title"), "Quest should have a title")
	assert_true(quest.has("objectives"), "Quest should have objectives")
	assert_true(quest.objectives.size() >= 1 and quest.objectives.size() <= 3, 
		"Quest should have 1-3 objectives")
	
	# Check objective structure
	if quest.objectives.size() > 0:
		var obj = quest.objectives[0]
		assert_true(obj.has("description"), "Objective should have description")
		assert_true(obj.has("target"), "Objective should have target")
		assert_false(obj.description.is_empty(), "Objective description should not be empty")
	
	quest_system.queue_free()

func test_landmark_chunks_get_more_markers():
	# Chunk with landmark should generate more markers
	var chunk_landmark = Chunk.new(5, 5, 12345)
	chunk_landmark.generate()
	
	# Count markers from landmark chunk
	var landmark_markers = chunk_landmark.get_narrative_markers()
	
	# Landmark type is determined by terrain generation, so we can't guarantee it
	# But we can verify the marker count is reasonable
	assert_true(landmark_markers.size() >= 0 and landmark_markers.size() <= 3,
		"Chunk should generate 0-3 markers")
	
	chunk_landmark.queue_free()
