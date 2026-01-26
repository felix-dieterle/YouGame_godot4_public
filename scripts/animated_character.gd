extends Node3D
class_name AnimatedCharacter

## Animated character using the Universal Animation Library
##
## This character can play various animations from the UAL library
## and can be placed around the world (near start point, houses, lighthouses)

# Character state
enum State { IDLE, WALKING, WAVING }
var current_state = State.IDLE

# Animation player reference
var animation_player: AnimationPlayer = null
var model: Node3D = null

# Movement parameters for walking characters
var walk_speed = 1.0
var walk_radius = 3.0  # How far from spawn point to walk
var spawn_position: Vector3 = Vector3.ZERO
var walk_timer: float = 0.0
var walk_direction: Vector3 = Vector3.ZERO
var state_timer: float = 0.0

# Character variation
var character_seed: int = 0

func _ready() -> void:
	spawn_position = global_position
	_load_character_model()
	_setup_initial_state()

## Load and setup the character model from GLB
func _load_character_model() -> void:
	# Load the GLB file
	var gltf = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var glb_path = "res://assets/animations/character_animations.glb"
	
	var error = gltf.append_from_file(glb_path, gltf_state)
	if error != OK:
		push_error("Failed to load character model: " + str(error))
		return
	
	# Generate the scene from GLTF
	model = gltf.generate_scene(gltf_state)
	if model:
		add_child(model)
		
		# Scale down the character to appropriate size (GLB models are often large)
		model.scale = Vector3(0.5, 0.5, 0.5)
		
		# Find the AnimationPlayer in the loaded model
		animation_player = _find_animation_player(model)
		
		if animation_player:
			# List available animations for debugging
			var anims = animation_player.get_animation_list()
			if anims.size() > 0:
				print("Available animations: ", anims)

## Recursively find AnimationPlayer node
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

## Setup initial character state
func _setup_initial_state() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = character_seed
	
	# Randomly choose initial state
	var state_choice = rng.randi() % 10
	if state_choice < 6:
		_set_state(State.IDLE)
	else:
		_set_state(State.WALKING)
	
	# Random rotation
	rotation.y = rng.randf_range(0, TAU)

## Set character state and play appropriate animation
func _set_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	if not animation_player:
		return
	
	var anims = animation_player.get_animation_list()
	if anims.size() == 0:
		return
	
	match current_state:
		State.IDLE:
			# Try to find an idle animation
			for anim_name in anims:
				var lower_name = anim_name.to_lower()
				if "idle" in lower_name or "stand" in lower_name:
					animation_player.play(anim_name)
					return
			# Fallback to first animation
			animation_player.play(anims[0])
		
		State.WALKING:
			# Try to find a walk animation
			for anim_name in anims:
				var lower_name = anim_name.to_lower()
				if "walk" in lower_name or "run" in lower_name:
					animation_player.play(anim_name)
					return
			# Fallback to second animation if available
			if anims.size() > 1:
				animation_player.play(anims[1])
			else:
				animation_player.play(anims[0])
		
		State.WAVING:
			# Try to find a wave/greet animation
			for anim_name in anims:
				var lower_name = anim_name.to_lower()
				if "wave" in lower_name or "greet" in lower_name or "hello" in lower_name:
					animation_player.play(anim_name)
					return
			# Fallback to idle
			_set_state(State.IDLE)

func _process(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		State.IDLE:
			# Stay idle for 3-8 seconds, then maybe walk
			if state_timer > 5.0:
				var rng = RandomNumberGenerator.new()
				rng.seed = character_seed + int(state_timer * 1000)
				if rng.randf() < 0.3:  # 30% chance to start walking
					walk_direction = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
					_set_state(State.WALKING)
		
		State.WALKING:
			# Walk for 2-5 seconds, then go back to idle
			if state_timer > 3.0:
				_set_state(State.IDLE)
			else:
				# Move character
				var movement = walk_direction * walk_speed * delta
				var new_pos = global_position + movement
				
				# Keep within walk radius
				if spawn_position.distance_to(new_pos) < walk_radius:
					global_position = new_pos
					# Face movement direction
					if movement.length() > 0.01:
						look_at(global_position + movement, Vector3.UP)
				else:
					# Hit boundary, turn around
					walk_direction = -walk_direction
					look_at(global_position + walk_direction, Vector3.UP)

## Adjust character to terrain height
func adjust_to_terrain(world_manager) -> void:
	if not world_manager:
		return
	
	var world_x = global_position.x
	var world_z = global_position.z
	
	# Find which chunk this position is in
	var chunk_x = int(floor(world_x / 32.0))
	var chunk_z = int(floor(world_z / 32.0))
	var chunk_key = Vector2i(chunk_x, chunk_z)
	
	if chunk_key in world_manager.chunks:
		var chunk = world_manager.chunks[chunk_key]
		var height = chunk.get_height_at_world_pos(world_x, world_z)
		global_position.y = height
		spawn_position = global_position
