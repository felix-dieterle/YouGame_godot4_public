extends Node
class_name NarrativeMarker

# Marker properties
var marker_id: String
var chunk_position: Vector2i
var world_position: Vector3
var marker_type: String  # e.g., "discovery", "encounter", "landmark"
var importance: float = 0.5  # 0.0 to 1.0
var is_activated: bool = false

# Associated metadata
var metadata: Dictionary = {}

func _init(id: String, chunk_pos: Vector2i, world_pos: Vector3, type: String):
	marker_id = id
	chunk_position = chunk_pos
	world_position = world_pos
	marker_type = type

func activate():
	is_activated = true

func get_data() -> Dictionary:
	return {
		"id": marker_id,
		"chunk_position": chunk_position,
		"world_position": world_position,
		"type": marker_type,
		"importance": importance,
		"is_activated": is_activated,
		"metadata": metadata
	}
