extends CharacterBody3D
class_name Player

# Movement settings
@export var move_speed: float = 5.0
@export var rotation_speed: float = 3.0
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0

# Camera
var camera: Camera3D

# World reference
var world_manager: WorldManager

func _ready():
	# Setup camera
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.look_at(global_position, Vector3.UP)
	
	# Find world manager
	world_manager = get_tree().get_first_node_in_group("WorldManager")
	
	# Create visual representation
	var mesh_instance = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.height = 2.0
	capsule.radius = 0.5
	mesh_instance.mesh = capsule
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.8)
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)

func _physics_process(delta):
	# Get input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		
		# Rotate towards movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * delta)
	
	move_and_slide()
	
	# Snap to terrain
	if world_manager:
		var target_height = world_manager.get_height_at_position(global_position)
		global_position.y = target_height + 1.0  # Half of player height

func _input(event):
	# Camera zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(20.0, camera_distance + 1.0)
			_update_camera()

func _update_camera():
	if camera:
		camera.position = Vector3(0, camera_height, camera_distance)
		camera.look_at(global_position, Vector3.UP)
