extends Node3D
class_name WorldManager

## Manages dynamic chunk loading and unloading based on player position
##
## The WorldManager is responsible for maintaining a VIEW_DISTANCE radius of chunks
## around the player at all times. It dynamically loads new chunks as the player moves
## and unloads chunks that are too far away to optimize memory usage.
##
## Key responsibilities:
## - Track player position and convert to chunk coordinates
## - Load chunks within VIEW_DISTANCE
## - Unload distant chunks
## - Coordinate with cluster systems for cross-chunk features
## - Manage initial world setup and starting location

# ============================================================================
# DEPENDENCIES
# ============================================================================

# Preload dependencies
const Chunk = preload("res://scripts/chunk.gd")
const StartingLocation = preload("res://scripts/starting_location.gd")
const TorchSystem = preload("res://scripts/torch_system.gd")

# ============================================================================
# CONFIGURATION
# ============================================================================

# Configuration
const CHUNK_SIZE = 32
const VIEW_DISTANCE = 3  # Number of chunks to load in each direction
const WORLD_SEED = 12345

# ============================================================================
# STATE
# ============================================================================

# Active chunks
var chunks: Dictionary = {}  # Key: Vector2i(x, z), Value: Chunk
var player_chunk: Vector2i = Vector2i(0, 0)

# Player reference
var player: Node3D

# UI reference
var ui_manager: Node = null

# Quest hook system reference
var quest_hook_system = null

# Initial loading state
var initial_loading_done: bool = false
var initial_loading_timer: Timer

# Starting location
var starting_location: StartingLocation = null

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
    # Find player or create a simple camera for testing
    player = get_parent().get_node_or_null("Player")
    if not player:
        player = get_parent().get_node_or_null("Camera3D")
    
    # Find UI manager
    ui_manager = get_parent().get_node_or_null("UIManager")
    
    # Find quest hook system
    quest_hook_system = get_parent().get_node_or_null("QuestHookSystem")
    
    # Create starting location
    starting_location = StartingLocation.new()
    add_child(starting_location)
    
    # Create initial loading timer
    initial_loading_timer = Timer.new()
    initial_loading_timer.one_shot = true
    initial_loading_timer.timeout.connect(_on_initial_loading_complete)
    add_child(initial_loading_timer)
    
    # Initial chunk loading
    _update_chunks()
    
    # Adjust starting location to terrain after first chunk is loaded
    if starting_location:
        starting_location.adjust_to_terrain(self)
    
    # Load placed torches from save file
    _load_placed_torches()
    
    # Mark initial loading as complete after a short delay
    initial_loading_timer.start(0.5)

func _on_initial_loading_complete() -> void:
    initial_loading_done = true
    if ui_manager:
        ui_manager.on_initial_loading_complete()

# ============================================================================
# CHUNK MANAGEMENT
# ============================================================================

func _process(_delta) -> void:
    if player:
        # Convert player world position to chunk coordinates
        # Note: Chunk coordinates are integers, world position is continuous
        var player_pos = player.global_position
        var new_chunk_x = int(floor(player_pos.x / CHUNK_SIZE))
        var new_chunk_z = int(floor(player_pos.z / CHUNK_SIZE))
        var new_player_chunk = Vector2i(new_chunk_x, new_chunk_z)
        
        # Only update chunks when player moves to a new chunk (performance optimization)
        if new_player_chunk != player_chunk:
            print("Chunk-Grenze überschritten: ", player_chunk, " -> ", new_player_chunk)
            player_chunk = new_player_chunk
            _update_chunks()

func _update_chunks() -> void:
    var chunks_to_load = []
    var chunks_to_keep = {}
    
    # Determine which chunks should be loaded based on VIEW_DISTANCE
    # Note: Vector2i.x stores world x-coord, Vector2i.y stores world z-coord
    for x in range(player_chunk.x - VIEW_DISTANCE, player_chunk.x + VIEW_DISTANCE + 1):
        for z in range(player_chunk.y - VIEW_DISTANCE, player_chunk.y + VIEW_DISTANCE + 1):
            var chunk_pos = Vector2i(x, z)
            chunks_to_load.append(chunk_pos)
            chunks_to_keep[chunk_pos] = true
    
    # Unload chunks that are too far away from player
    var chunks_to_remove = []
    for chunk_pos in chunks.keys():
        if not chunks_to_keep.has(chunk_pos):
            chunks_to_remove.append(chunk_pos)
    
    for chunk_pos in chunks_to_remove:
        _unload_chunk(chunk_pos)
    
    # Load new chunks
    for chunk_pos in chunks_to_load:
        if not chunks.has(chunk_pos):
            _load_chunk(chunk_pos)

func _load_chunk(chunk_pos: Vector2i) -> void:
    print("Neuer Chunk wird erzeugt: (", chunk_pos.x, ", ", chunk_pos.y, ")")
    var chunk = Chunk.new(chunk_pos.x, chunk_pos.y, WORLD_SEED)
    chunk.position = Vector3(chunk_pos.x * CHUNK_SIZE, 0, chunk_pos.y * CHUNK_SIZE)
    add_child(chunk)
    chunk.generate()
    chunks[chunk_pos] = chunk
    
    # Register narrative markers with quest hook system
    if quest_hook_system:
        var markers = chunk.get_narrative_markers()
        for marker in markers:
            quest_hook_system.register_marker(marker)
    
    # Notify UI manager
    if ui_manager and initial_loading_done:
        ui_manager.on_chunk_generated(chunk_pos)

func _unload_chunk(chunk_pos: Vector2i) -> void:
    if chunks.has(chunk_pos):
        var chunk = chunks[chunk_pos]
        chunk.queue_free()
        chunks.erase(chunk_pos)

func get_chunk_at_position(world_pos: Vector3) -> Chunk:
    var chunk_x = int(floor(world_pos.x / CHUNK_SIZE))
    var chunk_z = int(floor(world_pos.z / CHUNK_SIZE))
    var chunk_pos = Vector2i(chunk_x, chunk_z)
    return chunks.get(chunk_pos)

func get_height_at_position(world_pos: Vector3) -> float:
    var chunk = get_chunk_at_position(world_pos)
    if chunk:
        return chunk.get_height_at_world_pos(world_pos.x, world_pos.z)
    return 0.0

func get_water_depth_at_position(world_pos: Vector3) -> float:
    var chunk = get_chunk_at_position(world_pos)
    if chunk:
        var local_x = world_pos.x - chunk.chunk_x * CHUNK_SIZE
        var local_z = world_pos.z - chunk.chunk_z * CHUNK_SIZE
        return chunk.get_water_depth_at_local_pos(local_x, local_z)
    return 0.0

func get_terrain_material_at_position(world_pos: Vector3) -> String:
    var chunk = get_chunk_at_position(world_pos)
    if chunk:
        return chunk.get_terrain_material_at_world_pos(world_pos.x, world_pos.z)
    return "grass"

func get_slope_at_position(world_pos: Vector3) -> float:
    var chunk = get_chunk_at_position(world_pos)
    if chunk:
        return chunk.get_slope_at_world_pos(world_pos.x, world_pos.z)
    return 0.0

func get_slope_gradient_at_position(world_pos: Vector3) -> Vector3:
    var chunk = get_chunk_at_position(world_pos)
    if chunk:
        return chunk.get_slope_gradient_at_world_pos(world_pos.x, world_pos.z)
    return Vector3.ZERO

## Load placed torches from save file
func _load_placed_torches() -> void:
    if not SaveGameManager.has_save_file():
        return
    
    var world_data = SaveGameManager.get_world_data()
    if not "torches" in world_data:
        return
    
    var torch_positions = world_data["torches"]
    if not torch_positions is Array:
        return
    
    # Create torches at saved positions using TorchSystem
    for torch_data in torch_positions:
        if not torch_data is Dictionary:
            continue
        
        var pos = Vector3(
            torch_data.get("x", 0.0),
            torch_data.get("y", 0.0),
            torch_data.get("z", 0.0)
        )
        
        # Create torch using TorchSystem
        var torch = TorchSystem.create_torch_node()
        torch.global_position = pos
        add_child(torch)
    
    print("WorldManager: Loaded ", torch_positions.size(), " torches from save file")
