extends Node
class_name ProceduralModels

## Procedural Low-Poly Model Generation
##
## Generates simple, performance-friendly 3D models for:
## - Trees (for forests)
## - Buildings (for settlements)
## - Rocks (for terrain decoration)
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

# Rock generation constants
const ROCK_MIN_SIZE = 0.5
const ROCK_MAX_SIZE = 1.5
const ROCK_SEGMENTS = 6
const ROCK_COLORS = [
	Color(0.45, 0.45, 0.47),  # Light gray
	Color(0.35, 0.35, 0.37),  # Medium gray
	Color(0.42, 0.40, 0.38),  # Brownish gray
	Color(0.38, 0.36, 0.35)   # Dark brownish
]

# Lighthouse generation constants
const LIGHTHOUSE_TOWER_HEIGHT = 8.0
const LIGHTHOUSE_TOWER_RADIUS = 0.8
const LIGHTHOUSE_TOWER_SEGMENTS = 8
const LIGHTHOUSE_BEACON_HEIGHT = 1.5
const LIGHTHOUSE_BEACON_RADIUS = 1.2

# Fishing boat generation constants
const BOAT_LENGTH = 4.0
const BOAT_WIDTH = 1.5
const BOAT_HEIGHT = 0.8
const BOAT_SEGMENTS = 8
const BOAT_BENCH_OFFSET_RATIO = 0.2  # Position of bench along boat length
const BOAT_BENCH_THICKNESS_RATIO = 0.3  # Bench height relative to its base position

# Tree type enum
enum TreeType {
	AUTO = -1,  # Automatically select tree type based on seed
	CONIFER = 0,  # Pine/spruce trees
	BROAD_LEAF = 1,  # Oak/maple style
	SMALL_BUSH = 2  # Small vegetation
}

## Create a low-poly tree mesh with variations
static func create_tree_mesh(seed_val: int = 0, tree_type: int = TreeType.AUTO) -> ArrayMesh:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_val
    
    # Automatically pick tree type based on seed if set to AUTO
    if tree_type == TreeType.AUTO:
        var type_choice = rng.randi() % 10
        if type_choice < 4:
            tree_type = TreeType.CONIFER
        elif type_choice < 8:
            tree_type = TreeType.BROAD_LEAF
        else:
            tree_type = TreeType.SMALL_BUSH
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    match tree_type:
        TreeType.CONIFER:
            _create_conifer_tree(surface_tool, rng)
        TreeType.BROAD_LEAF:
            _create_broadleaf_tree(surface_tool, rng)
        TreeType.SMALL_BUSH:
            _create_small_bush(surface_tool, rng)
        _:
            # Fallback to broad-leaf if invalid type
            _create_broadleaf_tree(surface_tool, rng)
    
    surface_tool.generate_normals()
    return surface_tool.commit()

## Create a conifer (pine/spruce) tree
static func _create_conifer_tree(st: SurfaceTool, rng: RandomNumberGenerator):
    var trunk_height = TREE_TRUNK_HEIGHT * rng.randf_range(1.2, 1.5)
    var base_radius = TREE_CANOPY_RADIUS * rng.randf_range(0.6, 0.8)
    
    # Trunk (brown cylinder)
    _add_cylinder(st, Vector3.ZERO, trunk_height, TREE_TRUNK_RADIUS * 0.8, 
                  TREE_TRUNK_SEGMENTS, Color(0.35, 0.22, 0.13))
    
    # Multiple cone layers for conifer shape
    var layer_count = 3
    for i in range(layer_count):
        var layer_height = trunk_height + i * 0.8
        var cone_height = 1.5
        var cone_radius = base_radius * (1.0 - i * 0.25)
        var green_shade = rng.randf_range(0.15, 0.25)
        _add_cone(st, Vector3(0, layer_height, 0), cone_height, 
                  cone_radius, TREE_CANOPY_SEGMENTS, Color(green_shade, 0.5 + green_shade, green_shade))

## Create a broad-leaf tree (original style)
static func _create_broadleaf_tree(st: SurfaceTool, rng: RandomNumberGenerator):
    var trunk_height = TREE_TRUNK_HEIGHT * rng.randf_range(0.9, 1.1)
    var canopy_radius = TREE_CANOPY_RADIUS * rng.randf_range(0.8, 1.2)
    var canopy_height = TREE_CANOPY_HEIGHT * rng.randf_range(0.9, 1.1)
    
    # Trunk (brown cylinder)
    _add_cylinder(st, Vector3.ZERO, trunk_height, TREE_TRUNK_RADIUS, 
                  TREE_TRUNK_SEGMENTS, Color(0.4, 0.25, 0.15))
    
    # Canopy (green cone)
    var green_variation = rng.randf_range(-0.1, 0.1)
    _add_cone(st, Vector3(0, trunk_height, 0), canopy_height, 
              canopy_radius, TREE_CANOPY_SEGMENTS, Color(0.2 + green_variation, 0.6 + green_variation, 0.2 + green_variation))

## Create a small bush
static func _create_small_bush(st: SurfaceTool, rng: RandomNumberGenerator):
    var bush_height = 1.0 * rng.randf_range(0.8, 1.3)
    var bush_radius = 0.8 * rng.randf_range(0.9, 1.2)
    
    # Small trunk stub
    _add_cylinder(st, Vector3.ZERO, bush_height * 0.3, TREE_TRUNK_RADIUS * 0.5, 
                  4, Color(0.3, 0.2, 0.1))
    
    # Round bush top (cone with wide base)
    var green_shade = rng.randf_range(0.25, 0.35)
    _add_cone(st, Vector3(0, bush_height * 0.2, 0), bush_height, 
              bush_radius, 6, Color(green_shade, 0.55, green_shade))

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

## Create a low-poly rock mesh
static func create_rock_mesh(seed_val: int = 0) -> ArrayMesh:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_val
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Randomize rock size and proportions
    var base_size = rng.randf_range(ROCK_MIN_SIZE, ROCK_MAX_SIZE)
    var height = base_size * rng.randf_range(0.6, 1.2)
    
    # Create irregular rock shape by deforming vertices
    var vertices = []
    var angle_step = TAU / ROCK_SEGMENTS
    
    # Generate base vertices with random deformation
    for i in range(ROCK_SEGMENTS):
        var angle = i * angle_step
        var radius_variation = rng.randf_range(0.7, 1.3)
        var x = cos(angle) * base_size * radius_variation
        var z = sin(angle) * base_size * radius_variation
        vertices.append(Vector3(x, 0, z))
    
    # Top point with random offset
    var top_offset = Vector3(
        rng.randf_range(-0.2, 0.2) * base_size,
        height,
        rng.randf_range(-0.2, 0.2) * base_size
    )
    
    # Use predefined rock colors
    var rock_color = ROCK_COLORS[rng.randi() % ROCK_COLORS.size()]
    
    # Add slight color variation per face
    var color_var = 0.08
    
    # Create bottom cap
    for i in range(ROCK_SEGMENTS):
        var next_i = (i + 1) % ROCK_SEGMENTS
        var face_color = rock_color * rng.randf_range(1.0 - color_var, 1.0 + color_var)
        
        surface_tool.set_color(face_color)
        surface_tool.add_vertex(Vector3.ZERO)
        surface_tool.add_vertex(vertices[next_i])
        surface_tool.add_vertex(vertices[i])
    
    # Create side faces to top
    for i in range(ROCK_SEGMENTS):
        var next_i = (i + 1) % ROCK_SEGMENTS
        var face_color = rock_color * rng.randf_range(1.0 - color_var, 1.0 + color_var)
        
        surface_tool.set_color(face_color)
        surface_tool.add_vertex(vertices[i])
        surface_tool.add_vertex(vertices[next_i])
        surface_tool.add_vertex(top_offset)
    
    surface_tool.generate_normals()
    return surface_tool.commit()

## Create a material for rocks
static func create_rock_material() -> StandardMaterial3D:
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material.roughness = 0.95  # Rocks are very rough
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material

## Helper: Add a cylinder section (no top/bottom caps) for tower sections
static func _add_cylinder_section(st: SurfaceTool, base_pos: Vector3, height: float, 
                                  radius: float, segments: int, color: Color):
    var angle_step = TAU / segments
    
    # Side faces only
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

## Create a low-poly lighthouse mesh
static func create_lighthouse_mesh(seed_val: int = 0) -> ArrayMesh:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_val
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Tower colors - white with red/black stripes pattern
    var white_color = Color(0.95, 0.95, 0.95)
    var red_color = Color(0.8, 0.2, 0.2)
    
    # Build tower in sections with alternating colors
    var num_sections = 4
    var section_height = LIGHTHOUSE_TOWER_HEIGHT / num_sections
    
    for i in range(num_sections):
        var y_offset = i * section_height
        var color = white_color if i % 2 == 0 else red_color
        _add_cylinder_section(st, Vector3(0, y_offset, 0), 
                              section_height, LIGHTHOUSE_TOWER_RADIUS, 
                              LIGHTHOUSE_TOWER_SEGMENTS, color)
    
    # Add beacon platform (dark gray)
    var platform_y = LIGHTHOUSE_TOWER_HEIGHT
    _add_cylinder_section(st, Vector3(0, platform_y, 0), 0.3, 
                          LIGHTHOUSE_BEACON_RADIUS * 0.9, LIGHTHOUSE_TOWER_SEGMENTS, 
                          Color(0.3, 0.3, 0.3))
    
    # Add beacon light housing (yellow/gold glass)
    var beacon_y = platform_y + 0.3
    _add_cylinder_section(st, Vector3(0, beacon_y, 0), 
                          LIGHTHOUSE_BEACON_HEIGHT, LIGHTHOUSE_BEACON_RADIUS * 0.7, 
                          LIGHTHOUSE_TOWER_SEGMENTS, Color(0.9, 0.8, 0.3, 0.7))
    
    # Add beacon roof (red cone)
    var roof_y = beacon_y + LIGHTHOUSE_BEACON_HEIGHT
    _add_cone(st, Vector3(0, roof_y, 0), 1.0, 
              LIGHTHOUSE_BEACON_RADIUS * 0.8, LIGHTHOUSE_TOWER_SEGMENTS, red_color)
    
    st.generate_normals()
    return st.commit()

## Create a material for lighthouses
static func create_lighthouse_material() -> StandardMaterial3D:
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material.roughness = 0.6
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material

## Create a low-poly fishing boat mesh
static func create_fishing_boat_mesh(seed_val: int = 0) -> ArrayMesh:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_val
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Boat colors - weathered wood brown
    var wood_color = Color(0.45, 0.35, 0.25)
    var dark_wood = Color(0.35, 0.25, 0.18)
    
    # Boat hull - create a simple boat shape with pointed front
    var half_width = BOAT_WIDTH / 2.0
    var half_length = BOAT_LENGTH / 2.0
    
    # Define hull vertices (bottom is flat for sitting in sand)
    # Bottom vertices (y = 0)
    var bottom_front = Vector3(half_length, 0, 0)  # Pointed front
    var bottom_left_mid = Vector3(0, 0, -half_width)
    var bottom_right_mid = Vector3(0, 0, half_width)
    var bottom_left_back = Vector3(-half_length * 0.8, 0, -half_width * 0.7)
    var bottom_right_back = Vector3(-half_length * 0.8, 0, half_width * 0.7)
    var bottom_back = Vector3(-half_length, 0, 0)  # Slightly pointed back
    
    # Top vertices (y = BOAT_HEIGHT)
    var top_front = Vector3(half_length * 0.9, BOAT_HEIGHT, 0)
    var top_left_mid = Vector3(0, BOAT_HEIGHT, -half_width * 0.8)
    var top_right_mid = Vector3(0, BOAT_HEIGHT, half_width * 0.8)
    var top_left_back = Vector3(-half_length * 0.7, BOAT_HEIGHT, -half_width * 0.6)
    var top_right_back = Vector3(-half_length * 0.7, BOAT_HEIGHT, half_width * 0.6)
    var top_back = Vector3(-half_length * 0.85, BOAT_HEIGHT, 0)
    
    # Create hull sides - left side
    st.set_color(wood_color)
    st.add_vertex(bottom_front)
    st.add_vertex(top_left_mid)
    st.add_vertex(top_front)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_front)
    st.add_vertex(bottom_left_mid)
    st.add_vertex(top_left_mid)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_left_mid)
    st.add_vertex(top_left_back)
    st.add_vertex(top_left_mid)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_left_mid)
    st.add_vertex(bottom_left_back)
    st.add_vertex(top_left_back)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_left_back)
    st.add_vertex(top_back)
    st.add_vertex(top_left_back)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_left_back)
    st.add_vertex(bottom_back)
    st.add_vertex(top_back)
    
    # Right side (mirror of left)
    st.set_color(wood_color)
    st.add_vertex(bottom_front)
    st.add_vertex(top_front)
    st.add_vertex(top_right_mid)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_front)
    st.add_vertex(top_right_mid)
    st.add_vertex(bottom_right_mid)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_right_mid)
    st.add_vertex(top_right_mid)
    st.add_vertex(top_right_back)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_right_mid)
    st.add_vertex(top_right_back)
    st.add_vertex(bottom_right_back)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_right_back)
    st.add_vertex(top_right_back)
    st.add_vertex(top_back)
    
    st.set_color(wood_color)
    st.add_vertex(bottom_right_back)
    st.add_vertex(top_back)
    st.add_vertex(bottom_back)
    
    # Front triangular face
    st.set_color(dark_wood)
    st.add_vertex(bottom_front)
    st.add_vertex(top_front)
    st.add_vertex(top_left_mid)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_front)
    st.add_vertex(top_left_mid)
    st.add_vertex(bottom_left_mid)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_front)
    st.add_vertex(bottom_right_mid)
    st.add_vertex(top_right_mid)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_front)
    st.add_vertex(top_right_mid)
    st.add_vertex(top_front)
    
    # Back face
    st.set_color(dark_wood)
    st.add_vertex(bottom_back)
    st.add_vertex(top_left_back)
    st.add_vertex(top_back)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_back)
    st.add_vertex(bottom_left_back)
    st.add_vertex(top_left_back)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_back)
    st.add_vertex(top_back)
    st.add_vertex(top_right_back)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_back)
    st.add_vertex(top_right_back)
    st.add_vertex(bottom_right_back)
    
    # Bottom (flat for sitting in sand)
    st.set_color(dark_wood)
    st.add_vertex(bottom_front)
    st.add_vertex(bottom_left_mid)
    st.add_vertex(bottom_right_mid)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_left_mid)
    st.add_vertex(bottom_left_back)
    st.add_vertex(bottom_right_back)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_left_mid)
    st.add_vertex(bottom_right_back)
    st.add_vertex(bottom_right_mid)
    
    st.set_color(dark_wood)
    st.add_vertex(bottom_left_back)
    st.add_vertex(bottom_back)
    st.add_vertex(bottom_right_back)
    
    # Add a simple bench seat inside (darker wood)
    var bench_y = BOAT_HEIGHT * 0.4
    var bench_width = BOAT_WIDTH * 0.6
    var bench_length = BOAT_LENGTH * 0.5
    _add_box(st, Vector3(-bench_length * BOAT_BENCH_OFFSET_RATIO, bench_y, 0), 
             Vector3(bench_length, bench_y * BOAT_BENCH_THICKNESS_RATIO, bench_width), dark_wood)
    
    st.generate_normals()
    return st.commit()

## Create a material for fishing boats
static func create_fishing_boat_material() -> StandardMaterial3D:
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material.roughness = 0.8  # Weathered wood
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material
