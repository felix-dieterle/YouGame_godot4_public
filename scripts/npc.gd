extends CharacterBody3D
class_name NPC

enum State { IDLE, WALK }

# State machine
var current_state: State = State.IDLE
var state_timer: float = 0.0

# Movement
var walk_speed: float = 2.0
var walk_direction: Vector3 = Vector3.ZERO

# References
var world_manager: WorldManager

func _ready():
	# Create a simple visual representation
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.5, 1.5, 0.5)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.5, 0.2)
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)
	
	# Find world manager
	world_manager = get_tree().get_first_node_in_group("WorldManager")
	
	_transition_to_state(State.IDLE)

func _physics_process(delta):
	state_timer -= delta
	
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.WALK:
			_update_walk(delta)
	
	# Snap to terrain height
	if world_manager:
		var target_height = world_manager.get_height_at_position(global_position)
		global_position.y = target_height + 0.75  # Half of NPC height

func _update_idle(_delta):
	if state_timer <= 0.0:
		_transition_to_state(State.WALK)

func _update_walk(delta):
	velocity = walk_direction * walk_speed
	move_and_slide()
	
	if state_timer <= 0.0:
		_transition_to_state(State.IDLE)

func _transition_to_state(new_state: State):
	current_state = new_state
	
	match new_state:
		State.IDLE:
			state_timer = randf_range(2.0, 5.0)
			velocity = Vector3.ZERO
		State.WALK:
			state_timer = randf_range(3.0, 6.0)
			var angle = randf() * TAU
			walk_direction = Vector3(cos(angle), 0, sin(angle))
