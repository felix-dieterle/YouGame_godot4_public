extends CharacterBody3D
class_name Player

# Movement settings
@export var move_speed: float = 5.0
@export var rotation_speed: float = 3.0
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0
@export var max_slope_angle: float = 30.0  # Maximum walkable slope in degrees

# Slope detection settings - distances to look ahead when checking for steep slopes
@export var slope_check_near: float = 0.3   # Near check - about one step ahead
@export var slope_check_medium: float = 1.0 # Medium check - a few steps ahead
@export var slope_check_far: float = 2.5    # Far check - catch steep edges from a distance

# First-person settings
@export var first_person_height: float = 1.6
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.1

# Camera
var camera: Camera3D
var is_first_person: bool = false
var head_bob_time: float = 0.0

# Footstep sound system
var footstep_player: AudioStreamPlayer
var footstep_timer: float = 0.0
var footstep_interval: float = 0.5  # Time between footsteps when moving
var last_terrain_material: String = "grass"
const FOOTSTEP_DURATION: float = 0.15  # Sound duration in seconds

# World reference
var world_manager  # WorldManager - type hint removed to avoid preload dependency

# Mobile controls reference
var mobile_controls: Node = null

# Robot body parts for visibility toggle
var robot_parts: Array[Node3D] = []

# Input control
var input_enabled: bool = true

func _ready():
    # Add to Player group so other systems can find this node
    add_to_group("Player")
    
    # Configure CharacterBody3D slope handling
    floor_max_angle = deg_to_rad(max_slope_angle)
    
    # Setup camera
    camera = Camera3D.new()
    add_child(camera)
    camera.position = Vector3(0, camera_height, camera_distance)
    camera.look_at(global_position, Vector3.UP)
    
    # Find world manager
    world_manager = get_tree().get_first_node_in_group("WorldManager")
    
    # Find mobile controls
    mobile_controls = get_parent().get_node_or_null("MobileControls")
    
    # Setup footstep audio
    _setup_footstep_audio()
    
    # Create visual representation - Simple Robot
    _create_robot_body()
    
    # Load saved player state if available
    _load_saved_state()


func _physics_process(delta):
    # Check if input is disabled (e.g., during night)
    if not input_enabled:
        return
    
    # Get input - support both keyboard and mobile controls
    var input_dir = Vector2.ZERO
    
    # Try mobile controls first
    if mobile_controls:
        input_dir = mobile_controls.get_input_vector()
    
    # Fall back to keyboard if no mobile input
    # Note: ui_left/right/up/down are default Godot actions that work with arrow keys and WASD
    if input_dir.length() < 0.1:
        input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    
    # Convert input to direction vector
    # Input coordinate system: Y axis points down on screen (standard UI coordinates)
    # - Pushing up on joystick/keyboard gives negative Y
    # - Pushing down gives positive Y
    # - Pushing right on joystick/keyboard gives positive X
    # - Pushing left gives negative X
    # 3D coordinate system: In this game, forward movement is in +Z direction
    # - We negate input_dir.y to map "up" input to forward (+Z) movement
    # - We do NOT negate input_dir.x because the camera is behind the player (standard third-person)
    #   When camera is at +Z looking at player, screen-right corresponds to player's right (+X)
    # In first-person mode, direction is relative to player's facing direction
    # In third-person mode, direction is world-relative (original behavior)
    var direction = Vector3.ZERO
    if input_dir.length() > 0.01:
        if is_first_person:
            # First-person: Transform input by player's rotation
            # In first-person, the camera is rotated 180° (PI radians) to look forward
            # This means we need to invert the X-axis input so that right joystick = turn right
            # -input_dir.x → X axis (right/left, negated for first-person camera orientation)
            # -input_dir.y → Z axis (forward/back, negated to convert UI coords to 3D)
            var input_3d = Vector3(-input_dir.x, 0, -input_dir.y).normalized()
            direction = input_3d.rotated(Vector3.UP, rotation.y)
        else:
            # Third-person: World-relative movement
            # input_dir.x → X axis (east/west), -input_dir.y → Z axis (north/south, negated to convert UI coords to 3D)
            direction = Vector3(input_dir.x, 0, -input_dir.y).normalized()
    
    if direction:
        # Check slope along intended movement path
        var can_move = true
        
        if world_manager:
            # Check multiple points along the movement path to catch steep edges
            # Use configurable lookahead distances to ensure consistent behavior
            var check_distances = [slope_check_near, slope_check_medium, slope_check_far]
            
            for check_dist in check_distances:
                var check_position = global_position + direction * check_dist
                var slope_at_position = world_manager.get_slope_at_position(check_position)
                
                # Only restrict movement if slope is too steep AND we're moving uphill
                if slope_at_position > max_slope_angle:
                    # Get the slope gradient (direction of steepest ascent)
                    var slope_gradient = world_manager.get_slope_gradient_at_position(check_position)
                    
                    # Normalize gradient for dot product calculation
                    if slope_gradient.length_squared() > 0.0001:  # Check if gradient is non-zero
                        var normalized_gradient = slope_gradient.normalized()
                        
                        # Check if we're moving uphill by checking dot product
                        # If dot product > 0, we're moving in the uphill direction
                        var uphill_component = direction.dot(normalized_gradient)
                        
                        # Only block movement if we're moving uphill (positive dot product)
                        # Allow movement if going sideways (near 0) or downhill (negative)
                        if uphill_component > 0.1:  # Small threshold to allow slight angles
                            can_move = false
                            break  # Stop checking once we find a blocking slope
        
        if can_move:
            velocity.x = direction.x * move_speed
            velocity.z = direction.z * move_speed
            
            # Rotate towards movement direction (in both first and third person)
            # This allows turning with joystick in first-person mode
            var target_rotation = atan2(direction.x, direction.z)
            rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
            
            # Update head bob when moving in first-person
            if is_first_person:
                head_bob_time += delta * head_bob_frequency
            
            # Handle footstep sounds
            _update_footsteps(delta)
        else:
            # Stop movement if trying to climb too steep slope
            velocity.x = move_toward(velocity.x, 0, move_speed * delta * 2.0)
            velocity.z = move_toward(velocity.z, 0, move_speed * delta * 2.0)
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed * delta)
        velocity.z = move_toward(velocity.z, 0, move_speed * delta)
        
        # Reset head bob when not moving
        if is_first_person:
            head_bob_time = 0.0
        
        # Reset footstep timer when not moving
        footstep_timer = 0.0
    
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
            # In first-person, rotate 180° to look in opposite direction
            # Third-person camera looks at player's face, so first-person should look backward
            camera.rotation = Vector3(0, PI, 0)
        else:
            camera.position = Vector3(0, camera_height, camera_distance)
            camera.look_at(global_position, Vector3.UP)

func _toggle_camera_view():
    DebugLogOverlay.add_log("Player._toggle_camera_view() called", "yellow")
    
    is_first_person = not is_first_person
    _update_camera()
    
    DebugLogOverlay.add_log("Camera view toggled to: %s" % ("First Person" if is_first_person else "Third Person"), "green")
    
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

func _setup_footstep_audio():
    # Create audio player for footstep sounds
    footstep_player = AudioStreamPlayer.new()
    footstep_player.volume_db = -10.0  # Slightly quieter
    add_child(footstep_player)

func _update_footsteps(delta: float):
    # Update footstep timer
    footstep_timer += delta
    
    # Play footstep sound at regular intervals
    if footstep_timer >= footstep_interval:
        footstep_timer = 0.0
        _play_footstep_sound()

func _play_footstep_sound():
    # Get terrain material at current position
    var terrain_material = "grass"
    if world_manager:
        terrain_material = world_manager.get_terrain_material_at_position(global_position)
    
    # Create a simple procedural footstep sound based on material
    var generator = AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = FOOTSTEP_DURATION
    
    footstep_player.stream = generator
    
    # Start playback to get access to the playback buffer
    footstep_player.play()
    
    # Wait one frame for the stream to initialize
    await get_tree().process_frame
    
    # Generate the sound waveform in the playback buffer
    var playback = footstep_player.get_stream_playback() as AudioStreamGeneratorPlayback
    if not playback:
        return  # Stream not ready, skip this footstep
    
    var frames_available = playback.get_frames_available()
    var frames_to_fill = roundi(generator.mix_rate * FOOTSTEP_DURATION)
    var frequency = 100.0  # Base frequency
    var noise_amount = 0.5
    
    # Adjust sound characteristics based on material
    match terrain_material:
        "stone":
            frequency = 150.0
            noise_amount = 0.8  # More noise for hard surface
        "rock":
            frequency = 120.0
            noise_amount = 0.6
        "grass":
            frequency = 80.0
            noise_amount = 0.4  # Softer, less noise
    
    # Generate audio frames
    for i in range(min(frames_to_fill, frames_available)):
        var t = float(i) / generator.mix_rate
        var envelope = exp(-t * 15.0)  # Exponential decay
        
        # Mix tone with noise
        var tone = sin(2.0 * PI * frequency * t) * (1.0 - noise_amount)
        var noise_val = (randf() * 2.0 - 1.0) * noise_amount
        var sample = (tone + noise_val) * envelope * 0.3
        
        playback.push_frame(Vector2(sample, sample))

func set_input_enabled(enabled: bool):
    input_enabled = enabled

func _load_saved_state():
    # Get player state from SaveGameManager (already loaded at startup)
    if SaveGameManager.has_save_file():
        var player_data = SaveGameManager.get_player_data()
        
        # Restore player position
        global_position = player_data["position"]
        
        # Restore player rotation
        rotation.y = player_data["rotation_y"]
        
        # Restore camera mode
        if player_data["is_first_person"] != is_first_person:
            is_first_person = player_data["is_first_person"]
            _update_camera()
            
            # Update robot parts visibility
            for part in robot_parts:
                part.visible = not is_first_person
        
        print("Player: Loaded saved position: ", global_position)

