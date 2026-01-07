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

# Mobile controls reference
var mobile_controls: Node = null

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
	
	# Left eye - glowing sphere
	var left_eye = MeshInstance3D.new()
	var eye_mesh_left = SphereMesh.new()
	eye_mesh_left.radius = 0.12
	eye_mesh_left.height = 0.24
	left_eye.mesh = eye_mesh_left
	left_eye.position = Vector3(-0.15, 1.3, 0.25)
	
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.2, 0.8, 1.0)  # Cyan/blue
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.2, 0.8, 1.0)
	eye_material.emission_energy_multiplier = 2.0
	left_eye.set_surface_override_material(0, eye_material)
	add_child(left_eye)
	
	# Right eye - glowing sphere
	var right_eye = MeshInstance3D.new()
	var eye_mesh_right = SphereMesh.new()
	eye_mesh_right.radius = 0.12
	eye_mesh_right.height = 0.24
	right_eye.mesh = eye_mesh_right
	right_eye.position = Vector3(0.15, 1.3, 0.25)
	right_eye.set_surface_override_material(0, eye_material)
	add_child(right_eye)
	
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
