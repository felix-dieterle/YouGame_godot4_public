extends Node
class_name ProceduralModels

## Procedural Low-Poly Model Generation
##
## Generates simple, performance-friendly 3D models for:
## - Trees (for forests)
## - Buildings (for settlements)
## All models are optimized for mobile rendering

# Tree generation constants
const TREE_TRUNK_HEIGHT = 2.0
const TREE_TRUNK_RADIUS = 0.15
const TREE_CANOPY_RADIUS = 1.2
const TREE_CANOPY_HEIGHT = 2.5
const TREE_TRUNK_SEGMENTS = 6
const TREE_CANOPY_SEGMENTS = 8

# Building generation constants
const BUILDING_MIN_SIZE = Vector2(3.0, 3.0)
const BUILDING_MAX_SIZE = Vector2(6.0, 6.0)
const BUILDING_MIN_HEIGHT = 2.5
const BUILDING_MAX_HEIGHT = 5.0
const BUILDING_WALL_SEGMENTS = 4

## Create a low-poly tree mesh
static func create_tree_mesh(seed_val: int = 0) -> ArrayMesh:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_val
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Randomize tree proportions slightly
    var trunk_height = TREE_TRUNK_HEIGHT * rng.randf_range(0.9, 1.1)
    var canopy_radius = TREE_CANOPY_RADIUS * rng.randf_range(0.8, 1.2)
    var canopy_height = TREE_CANOPY_HEIGHT * rng.randf_range(0.9, 1.1)
    
    # Generate trunk (brown cylinder)
    _add_cylinder(surface_tool, Vector3.ZERO, trunk_height, TREE_TRUNK_RADIUS, 
                  TREE_TRUNK_SEGMENTS, Color(0.4, 0.25, 0.15))
    
    # Generate canopy (green cone)
    _add_cone(surface_tool, Vector3(0, trunk_height, 0), canopy_height, 
              canopy_radius, TREE_CANOPY_SEGMENTS, Color(0.2, 0.6, 0.2))
    
    surface_tool.generate_normals()
    return surface_tool.commit()

## Create a low-poly building mesh
static func create_building_mesh(seed_val: int = 0) -> ArrayMesh:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_val
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Randomize building dimensions
    var width = rng.randf_range(BUILDING_MIN_SIZE.x, BUILDING_MAX_SIZE.x)
    var depth = rng.randf_range(BUILDING_MIN_SIZE.y, BUILDING_MAX_SIZE.y)
    var height = rng.randf_range(BUILDING_MIN_HEIGHT, BUILDING_MAX_HEIGHT)
    
    # Random building color (earthy tones)
    var color_choices = [
        Color(0.7, 0.6, 0.5),  # Beige
        Color(0.6, 0.5, 0.4),  # Brown
        Color(0.8, 0.75, 0.7), # Light gray
        Color(0.5, 0.45, 0.4)  # Dark brown
    ]
    var wall_color = color_choices[rng.randi() % color_choices.size()]
    var roof_color = Color(0.5, 0.3, 0.2)  # Dark brown roof
    
    # Generate box (walls)
    _add_box(surface_tool, Vector3.ZERO, Vector3(width, height, depth), wall_color)
    
    # Generate pyramid roof
    _add_pyramid_roof(surface_tool, Vector3(0, height, 0), Vector3(width, depth, height * 0.4), roof_color)
    
    surface_tool.generate_normals()
    return surface_tool.commit()

## Helper: Add a cylinder to the mesh
static func _add_cylinder(st: SurfaceTool, base_pos: Vector3, height: float, 
                          radius: float, segments: int, color: Color):
    var angle_step = TAU / segments
    
    # Bottom cap
    for i in range(segments):
        var angle1 = i * angle_step
        var angle2 = (i + 1) * angle_step
        
        var p1 = base_pos + Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
        var p2 = base_pos + Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
        
        st.set_color(color)
        st.add_vertex(base_pos)
        st.add_vertex(p2)
        st.add_vertex(p1)
    
    # Side faces
    for i in range(segments):
        var angle1 = i * angle_step
        var angle2 = (i + 1) * angle_step
        
        var p1_bottom = base_pos + Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
        var p2_bottom = base_pos + Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
        var p1_top = p1_bottom + Vector3(0, height, 0)
        var p2_top = p2_bottom + Vector3(0, height, 0)
        
        st.set_color(color)
        st.add_vertex(p1_bottom)
        st.add_vertex(p2_bottom)
        st.add_vertex(p1_top)
        
        st.add_vertex(p2_bottom)
        st.add_vertex(p2_top)
        st.add_vertex(p1_top)

## Helper: Add a cone to the mesh
static func _add_cone(st: SurfaceTool, base_pos: Vector3, height: float, 
                      base_radius: float, segments: int, color: Color):
    var angle_step = TAU / segments
    var apex = base_pos + Vector3(0, height, 0)
    
    # Bottom cap
    for i in range(segments):
        var angle1 = i * angle_step
        var angle2 = (i + 1) * angle_step
        
        var p1 = base_pos + Vector3(cos(angle1) * base_radius, 0, sin(angle1) * base_radius)
        var p2 = base_pos + Vector3(cos(angle2) * base_radius, 0, sin(angle2) * base_radius)
        
        st.set_color(color)
        st.add_vertex(base_pos)
        st.add_vertex(p2)
        st.add_vertex(p1)
    
    # Side faces (triangles to apex)
    for i in range(segments):
        var angle1 = i * angle_step
        var angle2 = (i + 1) * angle_step
        
        var p1 = base_pos + Vector3(cos(angle1) * base_radius, 0, sin(angle1) * base_radius)
        var p2 = base_pos + Vector3(cos(angle2) * base_radius, 0, sin(angle2) * base_radius)
        
        st.set_color(color)
        st.add_vertex(p1)
        st.add_vertex(p2)
        st.add_vertex(apex)

## Helper: Add a box to the mesh
static func _add_box(st: SurfaceTool, base_pos: Vector3, size: Vector3, color: Color):
    var half_x = size.x / 2.0
    var half_z = size.z / 2.0
    
    # Define 8 corners
    var corners = [
        base_pos + Vector3(-half_x, 0, -half_z),      # 0: bottom front-left
        base_pos + Vector3(half_x, 0, -half_z),       # 1: bottom front-right
        base_pos + Vector3(half_x, 0, half_z),        # 2: bottom back-right
        base_pos + Vector3(-half_x, 0, half_z),       # 3: bottom back-left
        base_pos + Vector3(-half_x, size.y, -half_z), # 4: top front-left
        base_pos + Vector3(half_x, size.y, -half_z),  # 5: top front-right
        base_pos + Vector3(half_x, size.y, half_z),   # 6: top back-right
        base_pos + Vector3(-half_x, size.y, half_z)   # 7: top back-left
    ]
    
    # Define faces (2 triangles each)
    var faces = [
        # Bottom (y = 0)
        [0, 2, 1], [0, 3, 2],
        # Top (y = height)
        [4, 5, 6], [4, 6, 7],
        # Front (z = -half_z)
        [0, 1, 5], [0, 5, 4],
        # Back (z = half_z)
        [2, 3, 7], [2, 7, 6],
        # Left (x = -half_x)
        [3, 0, 4], [3, 4, 7],
        # Right (x = half_x)
        [1, 2, 6], [1, 6, 5]
    ]
    
    for face in faces:
        st.set_color(color)
        st.add_vertex(corners[face[0]])
        st.add_vertex(corners[face[1]])
        st.add_vertex(corners[face[2]])

## Helper: Add a pyramid roof to the mesh
static func _add_pyramid_roof(st: SurfaceTool, base_pos: Vector3, size: Vector3, color: Color):
    var half_x = size.x / 2.0
    var half_z = size.y / 2.0
    var apex = base_pos + Vector3(0, size.z, 0)
    
    # Define 4 base corners
    var corners = [
        base_pos + Vector3(-half_x, 0, -half_z),  # 0: front-left
        base_pos + Vector3(half_x, 0, -half_z),   # 1: front-right
        base_pos + Vector3(half_x, 0, half_z),    # 2: back-right
        base_pos + Vector3(-half_x, 0, half_z)    # 3: back-left
    ]
    
    # 4 triangular faces
    var faces = [
        [0, 1],  # Front
        [1, 2],  # Right
        [2, 3],  # Back
        [3, 0]   # Left
    ]
    
    for face in faces:
        st.set_color(color)
        st.add_vertex(corners[face[0]])
        st.add_vertex(corners[face[1]])
        st.add_vertex(apex)

## Create a material for trees
static func create_tree_material() -> StandardMaterial3D:
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material.roughness = 0.9
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material

## Create a material for buildings
static func create_building_material() -> StandardMaterial3D:
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material.roughness = 0.8
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material
