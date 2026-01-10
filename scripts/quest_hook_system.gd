extends Node
class_name QuestHookSystem

# Preload dependencies
const NarrativeMarker = preload("res://scripts/narrative_marker.gd")

# Quest hooks and markers
var available_markers: Array[NarrativeMarker] = []
var active_quests: Dictionary = {}  # Key: quest_id, Value: quest data

# Demo mode for generating dummy story elements
var demo_mode: bool = false
var story_templates: Dictionary = {
	"discovery": [
		"Explore the unknown area",
		"Investigate the mysterious location",
		"Survey the uncharted territory"
	],
	"encounter": [
		"Meet someone at this location",
		"Discover what awaits here",
		"Find out what's happening"
	],
	"landmark": [
		"Reach the notable landmark",
		"Visit the remarkable site",
		"Climb to the vantage point"
	]
}

func _ready():
	pass

func register_marker(marker: NarrativeMarker):
	available_markers.append(marker)

func create_quest_from_marker(marker: NarrativeMarker) -> Dictionary:
	var quest_id = "quest_" + str(available_markers.find(marker))
	
	var quest = {
		"id": quest_id,
		"marker": marker,
		"status": "active",
		"objectives": []
	}
	
	# Generate objectives based on marker type
	match marker.marker_type:
		"discovery":
			quest.objectives.append({
				"type": "reach_location",
				"target": marker.world_position,
				"completed": false
			})
		"encounter":
			quest.objectives.append({
				"type": "interact",
				"target": marker.world_position,
				"completed": false
			})
		"landmark":
			quest.objectives.append({
				"type": "explore",
				"target": marker.world_position,
				"completed": false
			})
	
	active_quests[quest_id] = quest
	marker.activate()
	
	return quest

func update_quest(quest_id: String, objective_index: int, completed: bool):
	if active_quests.has(quest_id):
		var quest = active_quests[quest_id]
		if objective_index < quest.objectives.size():
			quest.objectives[objective_index].completed = completed
		
		# Check if all objectives are completed
		var all_completed = true
		for objective in quest.objectives:
			if not objective.completed:
				all_completed = false
				break
		
		if all_completed:
			quest.status = "completed"

func get_nearby_markers(position: Vector3, radius: float) -> Array[NarrativeMarker]:
	var nearby: Array[NarrativeMarker] = []
	
	for marker in available_markers:
		if marker.is_activated:
			continue
		
		var distance = position.distance_to(marker.world_position)
		if distance <= radius:
			nearby.append(marker)
	
	return nearby

func select_quest_marker(position: Vector3, radius: float = 100.0) -> NarrativeMarker:
	var nearby = get_nearby_markers(position, radius)
	
	if nearby.size() == 0:
		return null
	
	# Select marker with highest importance
	var best_marker: NarrativeMarker = nearby[0]
	for marker in nearby:
		if marker.importance > best_marker.importance:
			best_marker = marker
	
	return best_marker

# Demo mode functions for generating dummy story elements
func enable_demo_mode():
	demo_mode = true
	print("QuestHookSystem: Demo mode enabled - will generate dummy story elements")

func disable_demo_mode():
	demo_mode = false

func generate_dummy_story_for_marker(marker: NarrativeMarker) -> String:
	# Generate a dummy story based on marker metadata
	if not demo_mode:
		return ""
	
	var story_parts = []
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(marker.marker_id)
	
	# Select template based on marker type
	var templates = story_templates.get(marker.marker_type, ["Investigate this area"])
	var template = templates[rng.randi() % templates.size()]
	
	# Add contextual information from metadata
	var biome = marker.metadata.get("biome", "unknown")
	var landmark = marker.metadata.get("landmark_type", "")
	var openness = marker.metadata.get("openness", 0.5)
	
	story_parts.append(template)
	
	# Add biome context
	story_parts.append("in the %s" % biome)
	
	# Add landmark context
	if landmark != "":
		if landmark == "hill":
			story_parts.append("near the elevated hill")
		elif landmark == "valley":
			story_parts.append("in the valley below")
	
	# Add openness context
	if openness > 0.7:
		story_parts.append("(open terrain)")
	else:
		story_parts.append("(rough terrain)")
	
	return " ".join(story_parts)

func create_demo_quest() -> Dictionary:
	# Create a demo quest with multiple markers
	if available_markers.size() == 0:
		print("QuestHookSystem: No markers available for demo quest")
		return {}
	
	# Use deterministic but varied seed for demo quest randomization
	# This ensures demo quests are random but reproducible per session
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	
	# Select 1-3 random markers for the quest
	var quest_markers = []
	var marker_count = min(rng.randi_range(1, 3), available_markers.size())
	
	# Get random markers
	var available_copy = available_markers.duplicate()
	for i in range(marker_count):
		var idx = rng.randi() % available_copy.size()
		quest_markers.append(available_copy[idx])
		available_copy.remove_at(idx)
	
	# Create quest
	var quest_id = "demo_quest_" + str(Time.get_ticks_msec())
	var quest = {
		"id": quest_id,
		"title": "Demo Quest: Journey Through the Land",
		"markers": quest_markers,
		"current_marker_index": 0,
		"status": "active",
		"objectives": []
	}
	
	# Create objectives from markers
	for i in range(quest_markers.size()):
		var marker = quest_markers[i]
		var story = generate_dummy_story_for_marker(marker)
		
		quest.objectives.append({
			"type": "reach_location",
			"marker": marker,
			"description": story,
			"target": marker.world_position,
			"completed": false
		})
	
	active_quests[quest_id] = quest
	
	if demo_mode:
		print("QuestHookSystem: Created demo quest '%s' with %d objectives" % [quest.title, quest_markers.size()])
		for i in range(quest.objectives.size()):
			print("  Objective %d: %s at %s" % [i + 1, quest.objectives[i].description, quest.objectives[i].target])
	
	return quest

func get_active_demo_quest() -> Dictionary:
	# Get the first active demo quest
	for quest_id in active_quests.keys():
		if quest_id.begins_with("demo_quest_"):
			return active_quests[quest_id]
	return {}

func print_marker_summary():
	# Debug function to print all available markers
	print("QuestHookSystem: %d markers available" % available_markers.size())
	for marker in available_markers:
		print("  - %s (type: %s, importance: %.2f) at %s" % [
			marker.marker_id,
			marker.marker_type,
			marker.importance,
			marker.world_position
		])

func get_total_marker_count() -> int:
	return available_markers.size()
