extends CharacterBody3D
class_name Player

# Preload dependencies
const CrystalSystem = preload("res://scripts/systems/collection/crystal_system.gd")
const TorchSystem = preload("res://scripts/systems/collection/torch_system.gd")
const CampfireSystem = preload("res://scripts/systems/collection/campfire_system.gd")
const Chunk = preload("res://scripts/systems/world/chunk.gd")

# Torch placement settings
@export var torch_placement_offset: float = 0.5  # Height offset when placing torch
@export var torch_light_energy: float = 5.0  # Brightness of torch light
@export var torch_light_range: float = 30.0  # How far torch light reaches
@export var torch_light_attenuation: float = 0.5  # Light falloff rate

# Campfire placement settings
@export var campfire_placement_offset: float = 0.0  # Height offset when placing campfire (on ground)
@export var campfire_light_energy: float = 8.0  # Brightness of campfire light
@export var campfire_light_range: float = 40.0  # How far campfire light reaches
@export var campfire_light_attenuation: float = 0.8  # Light falloff rate

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var rotation_speed: float = 3.0
@export var jetpack_speed: float = 3.0  # Upward speed when using jetpack
@export var jetpack_move_speed_multiplier: float = 4.0  # Horizontal speed multiplier when jetpack is active
@export var glide_speed: float = 0.5  # Slow descent speed when gliding after jetpack release
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0
@export var max_slope_angle: float = 30.0  # Maximum walkable slope in degrees

# Slope detection settings - distances to look ahead when checking for steep slopes
@export var slope_check_near: float = 0.3   # Near check - about one step ahead
@export var slope_check_medium: float = 1.0 # Medium check - a few steps ahead
@export var slope_check_far: float = 2.5    # Far check - catch steep edges from a distance

# Collision-safe landing settings
const LANDING_BINARY_SEARCH_ITERATIONS: int = 4  # Binary search iterations (halves search space each time, final precision: 1/16)
const LANDING_SAFETY_MARGIN: float = 0.05  # Additional safety buffer (5%) to account for floating-point precision

# First-person settings
@export var first_person_height: float = 1.6
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.1

# Camera
var camera: Camera3D
var is_first_person: bool = true
var head_bob_time: float = 0.0

# Camera rotation (for mouse/joystick look)
var camera_rotation_x: float = 0.0  # Vertical rotation (pitch)
var camera_rotation_y: float = 0.0  # Horizontal rotation (yaw)
@export var camera_sensitivity: float = 0.083333  # Reduced to 1/6 sensitivity (0.5/6) for half as sensitive look joystick
@export var camera_max_pitch: float = 80.0  # Maximum vertical look angle in degrees
@export var camera_max_yaw: float = 80.0  # Maximum horizontal look angle in degrees

# Footstep sound system
var footstep_player: AudioStreamPlayer
var footstep_timer: float = 0.0
var footstep_interval: float = 0.5  # Time between footsteps when moving
@export var sprint_footstep_multiplier: float = 0.5  # Multiplier for footstep interval when sprinting
var last_terrain_material: String = "grass"
const FOOTSTEP_DURATION: float = 0.15  # Sound duration in seconds
const JET_SOUND_INTERVAL_MULTIPLIER: float = 0.3  # Multiplier for jet sound interval (faster than footsteps)
const JET_HARMONIC_RATIO: float = 1.5  # Harmonic frequency multiplier for jet sound

# Preloaded sound effects
var footstep_sound: AudioStream
var jetpack_sound: AudioStream
var crystal_collect_sound: AudioStream
var crystal_collect_player: AudioStreamPlayer  # Reusable player for crystal sounds

# World reference
var world_manager  # WorldManager - type hint removed to avoid preload dependency

# Mobile controls reference
var mobile_controls: Node = null

# Robot body parts for visibility toggle
var robot_parts: Array[Node3D] = []

# Input control
var input_enabled: bool = true

# Sprint state
var is_sprinting: bool = false

# Crystal inventory - tracks collected crystals by type (initialized in _ready)
var crystal_inventory: Dictionary = {}

# Torch inventory
var torch_count: int = 100  # Player starts with 100 torches
var selected_item: String = "torch"  # Currently selected item

# New inventory items
var flint_stone_count: int = 2  # Player starts with 2 flint stones
var mushroom_count: int = 0  # Player starts with 0 mushrooms
var bottle_fill_level: float = 100.0  # Drinking bottle fill level (0-100)

# Flashlight system
@export var flashlight_energy: float = 3.0  # Brightness of flashlight
@export var flashlight_range: float = 50.0  # How far the flashlight reaches
@export var flashlight_angle: float = 75.0  # Outer cone angle (large cone)
@export var flashlight_angle_attenuation: float = 0.5  # Attenuation of light cone
@export var flashlight_color: Color = Color(1.0, 0.95, 0.9)  # Warm white light color
var flashlight: SpotLight3D = null  # Reference to the flashlight node
var flashlight_enabled: bool = true  # Flashlight state (default is ON)

# Glide state - tracks if player was using jetpack and should now glide
var is_gliding: bool = false
var was_jetpack_active: bool = false

# Air and health bar system
@export var max_air: float = 100.0  # Maximum air capacity
@export var max_health: float = 100.0  # Maximum health
@export var air_depletion_rate: float = 10.0  # Air lost per second when underwater
@export var health_depletion_rate: float = 5.0  # Health lost per second when air is empty underwater
@export var underwater_threshold: float = 0.5  # Water depth threshold to be considered underwater
var current_air: float = 100.0  # Current air level
var current_health: float = 100.0  # Current health
var is_underwater: bool = false  # Track if player is currently underwater

# Fall damage system
@export var fall_damage_threshold: float = 5.0  # Minimum fall height before damage starts (in meters)
@export var fall_damage_per_meter: float = 5.0  # Damage per meter fallen above threshold
var is_falling: bool = false  # Track if player is in the air
var fall_start_y: float = 0.0  # Y position where fall started

func _ready() -> void:
    # Add to Player group so other systems can find this node
    add_to_group("Player")
    
    # Initialize crystal inventory with all crystal types
    for crystal_type in CrystalSystem.CrystalType.values():
        crystal_inventory[crystal_type] = 0
    
    # Configure CharacterBody3D slope handling
    floor_max_angle = deg_to_rad(max_slope_angle)
    
    # Configure physics properties to prevent tunneling through walls
    # Safe margin creates a small buffer zone around the collision shape
    # This prevents high-speed movement from pushing through thin geometry
    safe_margin = 0.08
    
    # Setup camera
    camera = Camera3D.new()
    add_child(camera)
    camera.position = Vector3(0, camera_height, camera_distance)
    camera.look_at(global_position, Vector3.UP)
    
    # Setup flashlight (attached to camera)
    _setup_flashlight()
    
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
    
    # Update camera to match initial is_first_person state (if no saved state loaded)
    if not SaveGameManager.has_save_file():
        _update_camera()
        # Update robot parts visibility for initial first-person mode
        for part in robot_parts:
            part.visible = not is_first_person


func _physics_process(delta) -> void:
    # Check if input is disabled (e.g., during night)
    if not input_enabled:
        return
    
    # Handle jetpack input - check both keyboard and mobile controls
    var jetpack_active = _is_jetpack_active()
    
    # Update glide state based on jetpack transitions
    if jetpack_active:
        is_gliding = false
        was_jetpack_active = true
        # Reset fall tracking when jetpack activates (jetpack negates fall damage)
        is_falling = false
    elif was_jetpack_active:
        # Jetpack was just released - start gliding
        is_gliding = true
        was_jetpack_active = false
    
    # Apply jetpack upward movement or gliding descent
    # Set velocity to jetpack speed for consistent ascent
    # (Game uses terrain snapping instead of gravity, so direct velocity setting is appropriate)
    if jetpack_active:
        velocity.y = jetpack_speed
    elif is_gliding:
        # Apply slow downward glide when jetpack is released
        velocity.y = -glide_speed
    
    # Handle camera rotation from look joystick
    var look_input = Vector2.ZERO
    if mobile_controls and mobile_controls.has_method("get_look_vector"):
        # NEW: Use absolute position control instead of velocity
        if mobile_controls.has_method("has_look_input") and mobile_controls.has_look_input():
            # User is actively controlling the joystick - set camera to target angles
            if mobile_controls.has_method("get_look_target_angles"):
                var target_angles = mobile_controls.get_look_target_angles()
                camera_rotation_y = target_angles.x  # yaw
                camera_rotation_x = target_angles.y  # pitch
                
                # Clamp to ensure we stay within limits
                camera_rotation_x = clamp(camera_rotation_x, -deg_to_rad(camera_max_pitch), deg_to_rad(camera_max_pitch))
                camera_rotation_y = clamp(camera_rotation_y, -deg_to_rad(camera_max_yaw), deg_to_rad(camera_max_yaw))
                
                # Apply rotation to camera
                _update_camera_rotation()
        # If not actively touching, camera rotation stays at last set position
    
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
        
        # Skip slope checking when flying more than 1m above terrain
        var terrain_level = _get_terrain_level()
        var height_above_terrain = global_position.y - terrain_level
        
        # Only check slopes if we're close to the ground (within 1m)
        # When flying with jetpack or gliding high above terrain, skip slope checks
        if world_manager and height_above_terrain <= 1.0:
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
            # Use sprint speed if sprinting, otherwise use normal move speed
            var current_speed = sprint_speed if is_sprinting else move_speed
            # Apply jetpack speed multiplier when jetpack is active
            var current_move_speed = current_speed
            if jetpack_active:
                current_move_speed = move_speed * jetpack_move_speed_multiplier
            
            velocity.x = direction.x * current_move_speed
            velocity.z = direction.z * current_move_speed
            
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
    
    # Snap to terrain (only when jetpack is not active and not gliding)
    if world_manager:
        var terrain_level = _get_terrain_level()
        
        # Track fall state
        var height_above_terrain = global_position.y - terrain_level
        var is_airborne = _is_jetpack_active() or is_gliding or height_above_terrain > 0.5
        
        # Detect when player starts falling (goes airborne without jetpack or gliding)
        # Gliding is excluded because it's a controlled descent from jetpack and should not cause fall damage
        if is_airborne and not is_falling and not _is_jetpack_active() and not is_gliding:
            is_falling = true
            fall_start_y = global_position.y
        
        # Only snap to terrain when jetpack is not active and not gliding
        if not _is_jetpack_active() and not is_gliding:
            # Use collision-aware snapping to prevent sinking into ground
            _safe_snap_to_terrain(terrain_level)
            
            # Check if player just landed after falling
            if is_falling:
                _handle_fall_damage()
                is_falling = false
        elif is_gliding:
            # Check if player has reached or gone below terrain level while gliding
            if global_position.y <= terrain_level:
                # Stop gliding and perform safe landing
                is_gliding = false
                # Dampen velocity for smooth landing
                velocity.y = max(velocity.y * 0.1, -0.5)
                # Use collision-aware snapping to prevent clipping through terrain/walls
                _safe_snap_to_terrain(terrain_level)
                velocity.y = 0.0
                
                # Reset fall state - gliding is a controlled descent from jetpack and should not cause fall damage
                is_falling = false
    
    # Update air and health bars
    _update_air_and_health(delta)

func _input(event) -> void:
    # Sprint toggle
    if event.is_action_pressed("toggle_sprint"):
        is_sprinting = not is_sprinting
        DebugLogOverlay.add_log("Sprint toggled: %s" % ("ON" if is_sprinting else "OFF"), "cyan")
    
    # Camera view toggle
    if event.is_action_pressed("toggle_camera_view"):
        _toggle_camera_view()
    
    # Torch placement
    if event.is_action_pressed("place_torch"):
        _place_torch()
    
    # Use flint stones to create campfire
    if event.is_action_pressed("use_flint_stones"):
        _use_flint_stones()
    
    # Toggle inventory (show/hide)
    if event.is_action_pressed("toggle_inventory"):
        _toggle_inventory()
    
    # Toggle flashlight
    if event.is_action_pressed("toggle_flashlight"):
        _toggle_flashlight()
    
    # Camera zoom (only in third-person)
    if not is_first_person and event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = max(5.0, camera_distance - 1.0)
            _update_camera()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = min(20.0, camera_distance + 1.0)
            _update_camera()
    
    # Crystal collection on click/tap
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _try_collect_crystal(event.position)
    elif event is InputEventScreenTouch and event.pressed:
        _try_collect_crystal(event.position)

func _update_camera() -> void:
    if camera:
        if is_first_person:
            camera.position = Vector3(0, first_person_height, 0)
            # In first-person, rotate 180° to look in opposite direction
            # Third-person camera looks at player's face, so first-person should look backward
            camera.rotation = Vector3(0, PI, 0)
        else:
            camera.position = Vector3(0, camera_height, camera_distance)
            camera.look_at(global_position, Vector3.UP)

func _update_camera_rotation() -> void:
    # Apply rotation from joystick look controls
    # This works in both first-person and third-person modes
    if camera:
        if is_first_person:
            # In first-person, apply pitch and yaw with proper Euler order (Y-X-Z)
            # to avoid gimbal lock issues
            # Base rotation is PI (180°) to look forward, then apply user rotation
            # Using rotation_degrees for clearer logic
            var rotation_deg = Vector3(
                rad_to_deg(camera_rotation_x),  # Pitch (X-axis)
                rad_to_deg(PI + camera_rotation_y),  # Yaw (Y-axis) with base 180° rotation
                0.0  # Roll (Z-axis)
            )
            camera.rotation_degrees = rotation_deg
        else:
            # In third-person, rotate camera orbit around player
            # This creates a third-person camera that can look around the player
            var orbit_distance = camera_distance
            var orbit_height = camera_height
            
            # Calculate camera position based on rotation
            var horizontal_distance = orbit_distance * cos(camera_rotation_x)
            var camera_x = horizontal_distance * sin(camera_rotation_y)
            var camera_z = horizontal_distance * cos(camera_rotation_y)
            var camera_y = orbit_height + orbit_distance * sin(camera_rotation_x)
            
            camera.position = Vector3(camera_x, camera_y, camera_z)
            camera.look_at(global_position, Vector3.UP)

func _toggle_camera_view() -> void:
    DebugLogOverlay.add_log("Player._toggle_camera_view() called", "yellow")
    
    is_first_person = not is_first_person
    
    # Reset camera rotation when toggling views
    camera_rotation_x = 0.0
    camera_rotation_y = 0.0
    
    # Update camera position and apply rotation reset
    _update_camera()
    
    # If there was any residual rotation, ensure it's cleared
    if camera:
        if is_first_person:
            camera.rotation = Vector3(0, PI, 0)
        # In third-person, look_at will handle the orientation
    
    DebugLogOverlay.add_log("Camera view toggled to: %s" % ("First Person" if is_first_person else "Third Person"), "green")
    
    # Toggle visibility of robot body parts
    for part in robot_parts:
        part.visible = not is_first_person

func _create_robot_body() -> void:
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

func _setup_footstep_audio() -> void:
    # Preload sound effects once during initialization
    footstep_sound = load("res://assets/sounds/footstep_grass.wav")
    jetpack_sound = load("res://assets/sounds/jetpack.wav")
    crystal_collect_sound = load("res://assets/sounds/crystal_collect.wav")
    
    # Create audio player for footstep and jetpack sounds
    footstep_player = AudioStreamPlayer.new()
    footstep_player.volume_db = -10.0  # Slightly quieter
    add_child(footstep_player)
    
    # Create reusable audio player for crystal collection
    crystal_collect_player = AudioStreamPlayer.new()
    crystal_collect_player.stream = crystal_collect_sound
    crystal_collect_player.volume_db = -5.0
    add_child(crystal_collect_player)

func _update_footsteps(delta: float) -> void:
    # Update footstep timer
    footstep_timer += delta
    
    # Check if jetpack is active - play jet sounds instead of footsteps
    if _is_jetpack_active():
        # Play jet sound at regular intervals
        var jet_interval = footstep_interval * JET_SOUND_INTERVAL_MULTIPLIER  # Faster for continuous jet sound
        if footstep_timer >= jet_interval:
            footstep_timer = 0.0
            _play_jet_sound()
    else:
        # Play footstep sound at regular intervals (faster when sprinting)
        var current_interval = footstep_interval * (sprint_footstep_multiplier if is_sprinting else 1.0)
        if footstep_timer >= current_interval:
            footstep_timer = 0.0
            _play_footstep_sound()

func _play_footstep_sound() -> void:
    # Play the preloaded footstep sound
    if footstep_player and footstep_sound:
        footstep_player.stream = footstep_sound
        footstep_player.play()

func _play_jet_sound() -> void:
    # Play the preloaded jetpack sound
    if footstep_player and jetpack_sound:
        footstep_player.stream = jetpack_sound
        footstep_player.play()


func set_input_enabled(enabled: bool) -> void:
    input_enabled = enabled

## Handle fall damage when player lands after falling
func _handle_fall_damage() -> void:
    # Calculate fall distance
    var fall_distance = fall_start_y - global_position.y
    
    # Only apply damage if fall exceeds threshold
    if fall_distance > fall_damage_threshold:
        var excess_fall = fall_distance - fall_damage_threshold
        var damage = excess_fall * fall_damage_per_meter
        
        # Apply damage
        current_health = max(0.0, current_health - damage)
        
        # Trigger pain indicator
        _trigger_pain_indicator(damage)
        
        # Update UI
        _update_air_health_ui()
        
        # Check for game over
        if current_health <= 0.0:
            _trigger_game_over()
        
        # Log fall damage for debugging
        DebugLogOverlay.add_log("Fall damage: %.1f (fell %.1fm)" % [damage, fall_distance], "red")

## Trigger pain indicator when health is lost
func _trigger_pain_indicator(damage: float) -> void:
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("show_pain_indicator"):
        ui_manager.show_pain_indicator(damage)

## Update air and health bars based on underwater status
func _update_air_and_health(delta: float) -> void:
    if not world_manager:
        return
    
    # Check if player is underwater
    var water_depth = world_manager.get_water_depth_at_position(global_position)
    is_underwater = water_depth > underwater_threshold
    
    # Check if player is in border chunk
    var is_in_border = _is_in_border_chunk()
    
    var health_before = current_health
    
    if is_underwater:
        # Deplete air when underwater
        current_air = max(0.0, current_air - air_depletion_rate * delta)
        
        # If air is empty, deplete health
        if current_air <= 0.0:
            current_health = max(0.0, current_health - health_depletion_rate * delta)
            
            # Trigger pain indicator for drowning damage
            var damage_taken = health_before - current_health
            if damage_taken > 0.0:
                _trigger_pain_indicator(damage_taken)
            
            # Check for game over
            if current_health <= 0.0:
                _trigger_game_over()
    else:
        # Refill air immediately when above water
        current_air = max_air
    
    # Deplete health if in border chunk
    if is_in_border:
        current_health = max(0.0, current_health - get_border_health_drain_rate() * delta)
        
        # Trigger pain indicator for border damage
        var damage_taken = health_before - current_health
        if damage_taken > 0.0:
            _trigger_pain_indicator(damage_taken)
        
        # Check for game over
        if current_health <= 0.0:
            _trigger_game_over()
    
    # Update UI
    _update_air_health_ui()

## Check if player is in a border chunk
func _is_in_border_chunk() -> bool:
    if not world_manager:
        return false
    
    # Get current chunk
    var chunk = world_manager.get_chunk_at_position(global_position)
    if chunk:
        return chunk.is_border
    
    return false

## Get border health drain rate from chunk constants
func get_border_health_drain_rate() -> float:
    # Access the constant from Chunk class (preloaded at class level)
    return Chunk.BORDER_HEALTH_DRAIN_RATE

## Trigger game over when health reaches zero
func _trigger_game_over() -> void:
    # Disable player input
    set_input_enabled(false)
    
    # Show game over message
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("show_game_over"):
        ui_manager.show_game_over()

## Update air and health UI elements
func _update_air_health_ui() -> void:
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("update_air_health_bars"):
        ui_manager.update_air_health_bars(current_air, max_air, current_health, max_health)

## Get the terrain level at the player's current position (accounting for water depth)
func _get_terrain_level() -> float:
    if not world_manager:
        return 0.0
    
    var terrain_height = world_manager.get_height_at_position(global_position)
    var water_depth = world_manager.get_water_depth_at_position(global_position)
    return terrain_height + 1.0 - water_depth

## Safely snap player to terrain level while respecting collisions
## This prevents the player from sinking into ground or clipping through walls
func _safe_snap_to_terrain(terrain_level: float) -> void:
    var target_position = global_position
    target_position.y = terrain_level
    
    # Calculate the movement needed to reach terrain level
    var motion = target_position - global_position
    
    # Test if we can move to the target position without colliding
    var collision = test_move(global_transform, motion)
    
    if not collision:
        # Safe to move - no collision detected
        global_position.y = terrain_level
    else:
        # Collision detected - find the closest safe position using binary search
        var safe_fraction = 0.5
        var step = 0.25
        
        for i in range(LANDING_BINARY_SEARCH_ITERATIONS):
            var test_motion = motion * safe_fraction
            if test_move(global_transform, test_motion):
                # Collision - try closer position
                safe_fraction -= step
            else:
                # No collision - can go further
                safe_fraction += step
            step *= 0.5
        
        # Apply the safe movement with additional safety margin
        # The safety margin prevents floating-point precision issues from placing
        # the player exactly at collision boundaries, which could cause clipping
        var final_fraction = clamp(safe_fraction - LANDING_SAFETY_MARGIN, 0.0, 1.0)
        global_position += motion * final_fraction

## Check if jetpack is currently active from any input source
func _is_jetpack_active() -> bool:
    var active = Input.is_action_pressed("jetpack")
    if mobile_controls and mobile_controls.has_method("is_jetpack_pressed"):
        active = active or mobile_controls.is_jetpack_pressed()
    return active

## Try to collect a crystal at the screen position
func _try_collect_crystal(screen_pos: Vector2) -> void:
    if not camera:
        return
    
    # Raycast from camera through the clicked/tapped position
    var from = camera.project_ray_origin(screen_pos)
    var to = from + camera.project_ray_normal(screen_pos) * 1000.0
    
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = true
    query.collide_with_bodies = true  # Required for herb collection via StaticBody3D
    
    var result = space_state.intersect_ray(query)
    
    if result:
        var collider = result.collider
        # Check if we hit a crystal's interaction area
        if collider is Area3D:
            var crystal_node = collider.get_parent()
            if crystal_node and crystal_node.has_meta("is_crystal") and crystal_node.get_meta("is_crystal"):
                _collect_crystal(crystal_node)
                return  # Early return to prevent checking other types
        
        # Check if we hit a herb's collision body (StaticBody3D)
        if collider is StaticBody3D:
            var herb_node = collider.get_parent()
            if herb_node and herb_node.has_meta("is_herb") and herb_node.get_meta("is_herb"):
                _collect_herb(herb_node)
                return

## Collect a crystal and add to inventory
func _collect_crystal(crystal_node: Node3D) -> void:
    if not crystal_node.has_meta("crystal_type"):
        return
    
    var crystal_type = crystal_node.get_meta("crystal_type")
    
    # Add to inventory
    if crystal_type in crystal_inventory:
        crystal_inventory[crystal_type] += 1
    
    # Notify UI manager to update crystal counter
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("update_crystal_count"):
        ui_manager.update_crystal_count(crystal_inventory)
    
    # Remove the crystal from the scene with a small animation
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(crystal_node, "scale", Vector3.ZERO, 0.3)
    tween.tween_property(crystal_node, "position", crystal_node.position + Vector3(0, 1.0, 0), 0.3)
    tween.finished.connect(func(): crystal_node.queue_free())
    
    # Play collection sound effect using reusable player
    if crystal_collect_player:
        crystal_collect_player.play()

## Collect a herb and restore health
func _collect_herb(herb_node: Node3D) -> void:
    if not herb_node.has_meta("is_herb"):
        return
    
    # Restore health by 30% of max health
    var health_restore = max_health * 0.30
    current_health = min(max_health, current_health + health_restore)
    
    # Update UI
    _update_air_health_ui()
    
    # Remove the herb from the scene with a small animation
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(herb_node, "scale", Vector3.ZERO, 0.3)
    tween.tween_property(herb_node, "position", herb_node.position + Vector3(0, 0.5, 0), 0.3)
    tween.finished.connect(func(): herb_node.queue_free())
    
    # Play collection sound effect using reusable player (reuse crystal sound)
    if crystal_collect_player:
        crystal_collect_player.play()

func _load_saved_state():
    # Get player state from SaveGameManager (already loaded at startup)
    if SaveGameManager.has_save_file():
        var player_data = SaveGameManager.get_player_data()
        
        # Log player state being restored
        var log_msg = "PLAYER_LOAD | Position: %s | Rotation: %.2f | FirstPerson: %s | Health: %.1f | Air: %.1f" % [
            str(player_data["position"]),
            player_data["rotation_y"],
            str(player_data["is_first_person"]),
            player_data.get("current_health", max_health),
            player_data.get("current_air", max_air)
        ]
        LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
        
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
        
        # Restore inventory if available
        if "inventory" in player_data and player_data["inventory"] is Dictionary:
            # Convert JSON keys (strings) to integers for crystal types
            # JSON always serializes dictionary keys as strings
            var loaded_inventory = player_data["inventory"]
            # Update existing inventory values while preserving initialized structure
            for key in loaded_inventory:
                var int_key = int(key)
                if int_key in crystal_inventory:
                    crystal_inventory[int_key] = loaded_inventory[key]
            
            # Update UI with loaded inventory
            var ui_manager = get_tree().get_first_node_in_group("UIManager")
            if ui_manager and ui_manager.has_method("update_crystal_count"):
                ui_manager.update_crystal_count(crystal_inventory)
        
        # Restore torch count
        if "torch_count" in player_data:
            torch_count = player_data["torch_count"]
        
        # Restore selected item
        if "selected_item" in player_data:
            selected_item = player_data["selected_item"]
        
        # Restore air and health
        if "current_air" in player_data:
            current_air = player_data["current_air"]
        else:
            current_air = max_air  # Default to full if not in save
        
        if "current_health" in player_data:
            current_health = player_data["current_health"]
        else:
            current_health = max_health  # Default to full if not in save
        # Restore new inventory items
        if "flint_stone_count" in player_data:
            flint_stone_count = player_data["flint_stone_count"]
        
        if "mushroom_count" in player_data:
            mushroom_count = player_data["mushroom_count"]
        
        if "bottle_fill_level" in player_data:
            bottle_fill_level = player_data["bottle_fill_level"]
        
        # Restore flashlight state
        if "flashlight_enabled" in player_data:
            flashlight_enabled = player_data["flashlight_enabled"]
            if flashlight:
                flashlight.visible = flashlight_enabled
        
        # Check if we're loading during night lockout and disable input if so
        var day_night_data = SaveGameManager.get_day_night_data()
        if day_night_data.get("is_locked_out", false):
            var current_unix_time = Time.get_unix_time_from_system()
            var lockout_end_time = day_night_data.get("lockout_end_time", 0.0)
            # Only disable input if lockout hasn't expired yet
            if current_unix_time < lockout_end_time:
                input_enabled = false
                print("Player: Input disabled - loading during night lockout (%.1f seconds remaining)" % (lockout_end_time - current_unix_time))
        
        print("Player: Loaded saved position: ", global_position)

## Place a torch at the player's current position
func _place_torch() -> void:
    # Check if player has torches
    if torch_count <= 0:
        var ui_manager = get_tree().get_first_node_in_group("UIManager")
        if ui_manager and ui_manager.has_method("show_message"):
            ui_manager.show_message("No torches left!", 2.0)
        return
    
    # Deduct one torch from inventory
    torch_count -= 1
    
    # Create torch at player position using TorchSystem
    var torch = TorchSystem.create_torch_node(torch_light_energy, torch_light_range, torch_light_attenuation)
    torch.global_position = global_position + Vector3(0, torch_placement_offset, 0)
    
    # Add torch to the world
    get_parent().add_child(torch)
    
    # Update UI
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("update_torch_count"):
        ui_manager.update_torch_count(torch_count)
    if ui_manager and ui_manager.has_method("show_message"):
        ui_manager.show_message("Torch placed! (%d left)" % torch_count, 1.5)
    
    print("Player: Placed torch at ", torch.global_position, " - ", torch_count, " torches remaining")

## Use flint stones to create a campfire at the player's current position
func _use_flint_stones() -> void:
    # Check if player has enough flint stones
    if flint_stone_count < 2:
        var ui_manager = get_tree().get_first_node_in_group("UIManager")
        if ui_manager and ui_manager.has_method("show_message"):
            ui_manager.show_message("Need 2 flint stones to create campfire! (%d/2)" % flint_stone_count, 2.0)
        return
    
    # Deduct 2 flint stones from inventory
    flint_stone_count -= 2
    
    # Create campfire at player position using CampfireSystem
    var campfire = CampfireSystem.create_campfire_node(campfire_light_energy, campfire_light_range, campfire_light_attenuation)
    campfire.global_position = global_position + Vector3(0, campfire_placement_offset, 0)
    
    # Add campfire to the world
    get_parent().add_child(campfire)
    
    # Update UI
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("update_flint_stone_count"):
        ui_manager.update_flint_stone_count(flint_stone_count)
    if ui_manager and ui_manager.has_method("show_message"):
        ui_manager.show_message("Campfire created! (%d flint stones left)" % flint_stone_count, 2.0)
    
    print("Player: Created campfire at ", campfire.global_position, " - ", flint_stone_count, " flint stones remaining")

## Toggle inventory UI visibility
func _toggle_inventory() -> void:
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("toggle_inventory_ui"):
        ui_manager.toggle_inventory_ui()

## Setup flashlight attached to camera
func _setup_flashlight() -> void:
    flashlight = SpotLight3D.new()
    flashlight.name = "Flashlight"
    
    # Configure light properties for large light cone
    flashlight.light_energy = flashlight_energy
    flashlight.spot_range = flashlight_range
    flashlight.spot_angle = flashlight_angle  # Large cone angle
    flashlight.spot_angle_attenuation = flashlight_angle_attenuation
    flashlight.light_color = flashlight_color  # Warm white light
    flashlight.shadow_enabled = true
    
    # Attach flashlight to camera so it points where player looks
    camera.add_child(flashlight)
    flashlight.position = Vector3.ZERO  # Same position as camera
    
    # Flashlight is on by default
    flashlight.visible = flashlight_enabled
    
    print("Player: Flashlight created and attached to camera (default: ON)")

## Toggle flashlight on/off
func _toggle_flashlight() -> void:
    flashlight_enabled = not flashlight_enabled
    
    if flashlight:
        flashlight.visible = flashlight_enabled
    
    # Update UI
    var ui_manager = get_tree().get_first_node_in_group("UIManager")
    if ui_manager and ui_manager.has_method("show_message"):
        var status = "ON" if flashlight_enabled else "OFF"
        ui_manager.show_message("Flashlight: %s" % status, 1.5)
    
    # Update inventory UI
    if ui_manager and ui_manager.has_method("update_flashlight_status"):
        ui_manager.update_flashlight_status(flashlight_enabled)
    
    print("Player: Flashlight toggled ", "ON" if flashlight_enabled else "OFF")
