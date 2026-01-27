extends Node
class_name HerbSystem

## Herb Collection System
##
## Manages reddish herb generation in forests and collection mechanics
## Herbs spawn in dense forests and restore 30% health when collected

# Herb data structure
class HerbData:
	var world_pos: Vector3
	var size_scale: float  # 0.8 to 1.2 size variation
	
	func _init(pos: Vector3, scale: float):
		world_pos = pos
		size_scale = scale

# Herb configuration
const HERB_NAME = "Rötliches Kraut"  # Reddish herb
const HERB_COLOR = Color(0.7, 0.3, 0.25, 1.0)  # Reddish color
const HERB_LEAF_COLOR = Color(0.5, 0.6, 0.3, 1.0)  # Greenish leaves
const HERB_SPAWN_CHANCE = 0.08  # 8% chance per valid location in dense forests
const HERB_FOREST_DENSITY_THRESHOLD = 0.6  # Minimum forest density for herbs (larger forests)
const HERB_HEALTH_RESTORE_PERCENT = 0.30  # Restores 30% of max health

## Check if herbs can spawn based on forest density
static func can_spawn_in_forest(forest_density: float) -> bool:
	return forest_density >= HERB_FOREST_DENSITY_THRESHOLD

## Create a herb mesh (small reddish plant)
static func create_herb_mesh(size_scale: float, seed_val: int = 0) -> ArrayMesh:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Base size
	var base_radius = 0.08 * size_scale
	var stem_height = rng.randf_range(0.15, 0.25) * size_scale
	var leaf_count = rng.randi_range(3, 5)
	
	# Create stem (thin cylinder)
	var stem_segments = 4
	var angle_step = TAU / stem_segments
	
	# Stem bottom vertices
	var stem_bottom_verts = []
	for i in range(stem_segments):
		var angle = i * angle_step
		var x = cos(angle) * base_radius * 0.15
		var z = sin(angle) * base_radius * 0.15
		stem_bottom_verts.append(Vector3(x, 0, z))
	
	# Stem top vertices
	var stem_top_verts = []
	for i in range(stem_segments):
		var angle = i * angle_step
		var x = cos(angle) * base_radius * 0.15
		var z = sin(angle) * base_radius * 0.15
		stem_top_verts.append(Vector3(x, stem_height, z))
	
	# Create stem faces
	for i in range(stem_segments):
		var next_i = (i + 1) % stem_segments
		
		# Triangle 1
		surface_tool.set_color(HERB_COLOR * 0.8)
		surface_tool.add_vertex(stem_bottom_verts[i])
		surface_tool.add_vertex(stem_bottom_verts[next_i])
		surface_tool.add_vertex(stem_top_verts[i])
		
		# Triangle 2
		surface_tool.set_color(HERB_COLOR * 0.8)
		surface_tool.add_vertex(stem_bottom_verts[next_i])
		surface_tool.add_vertex(stem_top_verts[next_i])
		surface_tool.add_vertex(stem_top_verts[i])
	
	# Create leaves (small oval shapes)
	for i in range(leaf_count):
		var angle = rng.randf_range(0, TAU)
		var height = stem_height * rng.randf_range(0.4, 0.9)
		var leaf_length = base_radius * rng.randf_range(1.5, 2.5)
		var leaf_width = base_radius * rng.randf_range(0.6, 1.0)
		
		# Leaf origin point on stem
		var leaf_origin = Vector3(0, height, 0)
		
		# Leaf direction (outward from stem)
		var leaf_dir = Vector3(cos(angle), 0.2, sin(angle)).normalized()
		var leaf_right = leaf_dir.cross(Vector3.UP).normalized()
		
		# Leaf vertices (simple oval)
		var leaf_tip = leaf_origin + leaf_dir * leaf_length
		var leaf_left = leaf_origin + leaf_right * leaf_width
		var leaf_right_pos = leaf_origin - leaf_right * leaf_width
		
		# Leaf triangle 1
		surface_tool.set_color(HERB_LEAF_COLOR)
		surface_tool.add_vertex(leaf_origin)
		surface_tool.add_vertex(leaf_left)
		surface_tool.add_vertex(leaf_tip)
		
		# Leaf triangle 2
		surface_tool.set_color(HERB_LEAF_COLOR)
		surface_tool.add_vertex(leaf_origin)
		surface_tool.add_vertex(leaf_tip)
		surface_tool.add_vertex(leaf_right_pos)
	
	# Create flower/top (small reddish cluster)
	var flower_height = stem_height * 1.1
	var flower_segments = 5
	var flower_radius = base_radius * 0.8
	
	for i in range(flower_segments):
		var angle1 = i * (TAU / flower_segments)
		var angle2 = (i + 1) * (TAU / flower_segments)
		
		var x1 = cos(angle1) * flower_radius
		var z1 = sin(angle1) * flower_radius
		var x2 = cos(angle2) * flower_radius
		var z2 = sin(angle2) * flower_radius
		
		var v1 = Vector3(x1, flower_height, z1)
		var v2 = Vector3(x2, flower_height, z2)
		var apex = Vector3(0, flower_height + base_radius * 0.5, 0)
		
		# Flower petal
		surface_tool.set_color(HERB_COLOR)
		surface_tool.add_vertex(v1)
		surface_tool.add_vertex(v2)
		surface_tool.add_vertex(apex)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

## Create herb material
static func create_herb_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides of leaves
	material.roughness = 0.8  # Natural matte finish
	return material

## Calculate health restoration amount
static func get_health_restore_amount(max_health: float) -> float:
	return max_health * HERB_HEALTH_RESTORE_PERCENT
