extends Node3D
class_name StartingLocation

## Starting Location System
##
## Creates a simple starting area for the player with:
## - Basic procedural elements (no model files needed)
## - Plausible and simple generation
## - Always on walkable terrain

# Constants
const LOCATION_RADIUS = 8.0  # Radius of starting area
const NUM_MARKER_STONES = 6  # Number of marker stones around the area
const NUM_ANIMATED_CHARACTERS = 3  # Number of animated characters around starting area

# Starting location objects
var marker_stones: Array[MeshInstance3D] = []
var central_marker: MeshInstance3D = null
var animated_characters: Array = []

# World position of starting location (always at origin)
var world_position: Vector3 = Vector3(0, 0, 0)

func _ready() -> void:
    generate_starting_location()

## Generate the starting location
func generate_starting_location() -> void:
    _create_central_marker()
    _create_marker_stones()
    _create_animated_characters()

## Create central marker (a simple cairn/stone pile)
func _create_central_marker():
    central_marker = MeshInstance3D.new()
    
    # Create a simple cairn mesh (stacked stones)
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Base stone (larger)
    _add_stone_to_surface(surface_tool, Vector3(0, 0.3, 0), Vector3(0.8, 0.6, 0.8), Color(0.6, 0.6, 0.65))
    
    # Middle stone
    _add_stone_to_surface(surface_tool, Vector3(0, 0.9, 0), Vector3(0.6, 0.5, 0.6), Color(0.55, 0.55, 0.6))
    
    # Top stone (smaller)
    _add_stone_to_surface(surface_tool, Vector3(0, 1.5, 0), Vector3(0.4, 0.4, 0.4), Color(0.5, 0.5, 0.55))
    
    surface_tool.generate_normals()
    central_marker.mesh = surface_tool.commit()
    
    # Create material
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.roughness = 0.9
    central_marker.set_surface_override_material(0, material)
    central_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    
    add_child(central_marker)

## Add a box-shaped stone to the surface tool
func _add_stone_to_surface(surface_tool: SurfaceTool, center: Vector3, size: Vector3, color: Color):
    var half_size = size / 2.0
    
    # Define vertices for a box
    var vertices = [
        center + Vector3(-half_size.x, -half_size.y, -half_size.z),
        center + Vector3(half_size.x, -half_size.y, -half_size.z),
        center + Vector3(half_size.x, -half_size.y, half_size.z),
        center + Vector3(-half_size.x, -half_size.y, half_size.z),
        center + Vector3(-half_size.x, half_size.y, -half_size.z),
        center + Vector3(half_size.x, half_size.y, -half_size.z),
        center + Vector3(half_size.x, half_size.y, half_size.z),
        center + Vector3(-half_size.x, half_size.y, half_size.z),
    ]
    
    # Define faces (each face has 2 triangles)
    var faces = [
        # Bottom
        [0, 2, 1], [0, 3, 2],
        # Top
        [4, 5, 6], [4, 6, 7],
        # Front
        [0, 1, 5], [0, 5, 4],
        # Back
        [3, 7, 6], [3, 6, 2],
        # Left
        [0, 4, 7], [0, 7, 3],
        # Right
        [1, 2, 6], [1, 6, 5],
    ]
    
    for face in faces:
        for idx in face:
            surface_tool.set_color(color)
            surface_tool.add_vertex(vertices[idx])

## Create marker stones in a circle around the starting location
func _create_marker_stones():
    var rng = RandomNumberGenerator.new()
    rng.seed = 42  # Fixed seed for consistent starting location
    
    for i in range(NUM_MARKER_STONES):
        var angle = (float(i) / NUM_MARKER_STONES) * TAU
        var radius = LOCATION_RADIUS + rng.randf_range(-1.0, 1.0)
        
        var stone_pos = Vector3(
            cos(angle) * radius,
            0,  # Height will be adjusted to terrain
            sin(angle) * radius
        )
        
        # Create simple standing stone
        var stone = MeshInstance3D.new()
        var height = rng.randf_range(1.2, 2.0)
        var width = rng.randf_range(0.3, 0.5)
        
        # Create elongated box mesh
        var surface_tool = SurfaceTool.new()
        surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
        
        var stone_color = Color(0.5 + rng.randf_range(-0.1, 0.1), 0.5 + rng.randf_range(-0.1, 0.1), 0.55 + rng.randf_range(-0.1, 0.1))
        _add_stone_to_surface(surface_tool, Vector3(0, height / 2, 0), Vector3(width, height, width), stone_color)
        
        surface_tool.generate_normals()
        stone.mesh = surface_tool.commit()
        
        # Create material
        var material = StandardMaterial3D.new()
        material.vertex_color_use_as_albedo = true
        material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
        material.roughness = 0.9
        stone.set_surface_override_material(0, material)
        stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        
        # Position and slight random rotation
        stone.position = stone_pos
        stone.rotation.y = rng.randf_range(0, TAU)
        stone.rotation.x = rng.randf_range(-0.05, 0.05)  # Slight tilt
        stone.rotation.z = rng.randf_range(-0.05, 0.05)
        
        add_child(stone)
        marker_stones.append(stone)

## Create animated characters around the starting area
func _create_animated_characters() -> void:
    var rng = RandomNumberGenerator.new()
    rng.seed = 123  # Fixed seed for consistent character placement
    
    for i in range(NUM_ANIMATED_CHARACTERS):
        var character_scene = load("res://scenes/characters/animated_character.tscn")
        var character_instance = character_scene.instantiate()
        
        # Position characters around the starting area
        var angle = (float(i) / NUM_ANIMATED_CHARACTERS) * TAU + rng.randf_range(-0.3, 0.3)
        var radius = LOCATION_RADIUS * 0.6 + rng.randf_range(-1.0, 1.0)
        
        var char_pos = Vector3(
            cos(angle) * radius,
            0,  # Height will be adjusted to terrain
            sin(angle) * radius
        )
        
        character_instance.position = char_pos
        character_instance.character_seed = 1000 + i  # Unique seed for each character
        
        add_child(character_instance)
        animated_characters.append(character_instance)

## Adjust starting location to terrain height
func adjust_to_terrain(world_manager) -> void:
    if not world_manager:
        return
    
    # Adjust central marker
    var height = world_manager.get_height_at_position(world_position)
    central_marker.position.y = height
    
    # Adjust marker stones
    for stone in marker_stones:
        var stone_world_pos = world_position + stone.position
        var stone_height = world_manager.get_height_at_position(stone_world_pos)
        stone.position.y = stone_height
    
    # Adjust animated characters
    for character in animated_characters:
        character.adjust_to_terrain(world_manager)

## Get the world position of the starting location
func get_world_position() -> Vector3:
    return world_position
