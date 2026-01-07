extends Node
class_name QuestHookSystem

# Quest hooks and markers
var available_markers: Array[NarrativeMarker] = []
var active_quests: Dictionary = {}  # Key: quest_id, Value: quest data

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
