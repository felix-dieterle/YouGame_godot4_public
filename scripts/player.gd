extends CharacterBody3D
class_name Player

# Movement settings
@export var move_speed: float = 5.0
@export var rotation_speed: float = 3.0
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0

# First-person settings
@export var first_person_height: float = 1.6
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.1

# Camera
var camera: Camera3D
var is_first_person: bool = false
var head_bob_time: float = 0.0

# World reference
var world_manager: WorldManager

# Mobile controls reference
var mobile_controls: Node = null

# Robot body parts for visibility toggle
var robot_parts: Array[Node3D] = []

func _ready():
	# Setup camera
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.look_at(global_position, Vector3.UP)
	
	# Find world manager
	world_manager = get_tree().get_first_node_in_group("WorldManager")
	
	# Find mobile controls
	mobile_controls = get_parent().get_node_or_null("MobileControls")
	
	# Create visual representation - Simple Robot
	_create_robot_body()

func _physics_process(delta):
	# Get input - support both keyboard and mobile controls
	var input_dir = Vector2.ZERO
	
	# Try mobile controls first
	if mobile_controls:
		input_dir = mobile_controls.get_input_vector()
	
	# Fall back to keyboard if no mobile input
	# Note: ui_left/right/up/down are default Godot actions that work with arrow keys and WASD
	if input_dir.length() < 0.1:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		
		# Rotate towards movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		# Update head bob when moving in first-person
		if is_first_person:
			head_bob_time += delta * head_bob_frequency
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * delta)
		
		# Reset head bob when not moving
		if is_first_person:
			head_bob_time = 0.0
	
	move_and_slide()
	
	# Apply head bobbing in first-person
	if is_first_person and camera:
		var bob_offset = sin(head_bob_time) * head_bob_amplitude
		camera.position.y = first_person_height + bob_offset
	
	# Snap to terrain
	if world_manager:
		var target_height = world_manager.get_height_at_position(global_position)
		var water_depth = world_manager.get_water_depth_at_position(global_position)
		
		# Sink into water (knee-deep means player height is reduced)
		global_position.y = target_height + 1.0 - water_depth

func _input(event):
	# Camera view toggle
	if event.is_action_pressed("toggle_camera_view"):
		_toggle_camera_view()
	
	# Camera zoom (only in third-person)
	if not is_first_person and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(20.0, camera_distance + 1.0)
			_update_camera()

func _update_camera():
	if camera:
		if is_first_person:
			camera.position = Vector3(0, first_person_height, 0)
			camera.rotation = Vector3(0, 0, 0)
		else:
			camera.position = Vector3(0, camera_height, camera_distance)
			camera.look_at(global_position, Vector3.UP)

func _toggle_camera_view():
	is_first_person = not is_first_person
	_update_camera()
	
	# Toggle visibility of robot body parts
	for part in robot_parts:
		part.visible = not is_first_person

func _create_robot_body():
	# Robot body (main torso) - a box
	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.8, 1.0, 0.6)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.5, 0)
	
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.3, 0.3, 0.35)  # Dark gray
	body_material.metallic = 0.7
	body_material.roughness = 0.3
	body.set_surface_override_material(0, body_material)
	add_child(body)
	robot_parts.append(body)
	
	# Robot head - smaller box on top
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.6, 0.5, 0.5)
	head.mesh = head_mesh
	head.position = Vector3(0, 1.25, 0)
	
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.4, 0.4, 0.45)  # Lighter gray
	head_material.metallic = 0.6
	head_material.roughness = 0.4
	head.set_surface_override_material(0, head_material)
	add_child(head)
	robot_parts.append(head)
	
	# Create eyes - positioned at front of head to show facing direction
	var left_eye = _create_eye(Vector3(-0.15, 1.3, 0.25))
	add_child(left_eye)
	robot_parts.append(left_eye)
	
	var right_eye = _create_eye(Vector3(0.15, 1.3, 0.25))
	add_child(right_eye)
	robot_parts.append(right_eye)
	
	# Add a small antenna on top for character
	var antenna = MeshInstance3D.new()
	var antenna_mesh = CylinderMesh.new()
	antenna_mesh.height = 0.3
	antenna_mesh.top_radius = 0.03
	antenna_mesh.bottom_radius = 0.03
	antenna.mesh = antenna_mesh
	antenna.position = Vector3(0, 1.65, 0)
	
	var antenna_material = StandardMaterial3D.new()
	antenna_material.albedo_color = Color(0.8, 0.2, 0.2)  # Red
	antenna_material.metallic = 0.9
	antenna.set_surface_override_material(0, antenna_material)
	add_child(antenna)
	robot_parts.append(antenna)
	
	# Add antenna tip (small glowing sphere)
	var antenna_tip = MeshInstance3D.new()
	var tip_mesh = SphereMesh.new()
	tip_mesh.radius = 0.08
	tip_mesh.height = 0.16
	antenna_tip.mesh = tip_mesh
	antenna_tip.position = Vector3(0, 1.8, 0)
	
	var tip_material = StandardMaterial3D.new()
	tip_material.albedo_color = Color(1.0, 0.3, 0.3)
	tip_material.emission_enabled = true
	tip_material.emission = Color(1.0, 0.3, 0.3)
	tip_material.emission_energy_multiplier = 1.5
	antenna_tip.set_surface_override_material(0, tip_material)
	add_child(antenna_tip)
	robot_parts.append(antenna_tip)

func _create_eye(eye_position: Vector3) -> MeshInstance3D:
	# Helper function to create a glowing eye at the specified position
	var eye = MeshInstance3D.new()
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.12
	eye_mesh.height = 0.24
	eye.mesh = eye_mesh
	eye.position = eye_position
	
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.2, 0.8, 1.0)  # Cyan/blue
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.2, 0.8, 1.0)
	eye_material.emission_energy_multiplier = 2.0
	eye.set_surface_override_material(0, eye_material)
	
	return eye
