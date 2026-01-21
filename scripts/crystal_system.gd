extends Node
class_name CrystalSystem

## Crystal Collection System
##
## Manages crystal types, generation, and collection mechanics
## Crystals spawn on rocks and can be collected by tapping/clicking

# Crystal type definitions
enum CrystalType {
	MOUNTAIN_CRYSTAL,  # Clear/white crystal - common
	EMERALD,           # Green crystal - uncommon
	GARNET,            # Red crystal - uncommon
	RUBY,              # Deep red crystal - rare
	AMETHYST,          # Purple crystal - uncommon
	SAPPHIRE           # Blue crystal - rare
}

# Crystal data structure
class CrystalData:
	var type: CrystalType
	var size_scale: float  # 0.8 to 1.5 size variation
	var world_pos: Vector3
	var parent_rock: Node3D  # Reference to the rock it's on
	
	func _init(t: CrystalType, scale: float, pos: Vector3, rock: Node3D = null):
		type = t
		size_scale = scale
		world_pos = pos
		parent_rock = rock

# Crystal shape enum for different geometric forms
enum CrystalShape {
	HEXAGONAL_PRISM,  # Classic hexagonal crystal
	CUBIC,            # Cube-like crystal (e.g., for garnets)
	ELONGATED_PRISM,  # Tall thin prism (e.g., for emeralds)
	CLUSTER          # Multiple small points clustered together
}

# Crystal type configurations
# NOTE: spawn_chance values represent the probability distribution when a crystal spawns
# and must sum to 1.0 for proper weighted random selection
static var crystal_configs = {
	CrystalType.MOUNTAIN_CRYSTAL: {
		"name": "Mountain Crystal",
		"color": Color(0.9, 0.95, 1.0, 0.6),  # Clear/white with higher transparency
		"spawn_chance": 0.35,  # 35% chance when crystal spawns (common)
		"growth_frequency": 0.15,  # Reduced overall frequency
		"shape": CrystalShape.HEXAGONAL_PRISM,
		"preferred_rock_colors": [0, 1]  # Light and medium gray rocks
	},
	CrystalType.EMERALD: {
		"name": "Emerald",
		"color": Color(0.2, 0.8, 0.3, 0.65),  # Green with more transparency
		"spawn_chance": 0.30,  # 30% chance (uncommon)
		"growth_frequency": 0.10,  # Reduced overall frequency
		"shape": CrystalShape.ELONGATED_PRISM,
		"preferred_rock_colors": [2]  # Brownish gray rocks
	},
	CrystalType.GARNET: {
		"name": "Garnet",
		"color": Color(0.7, 0.2, 0.2, 0.7),  # Dark red with more transparency
		"spawn_chance": 0.20,  # 20% chance (uncommon)
		"growth_frequency": 0.08,  # Reduced overall frequency
		"shape": CrystalShape.CUBIC,
		"preferred_rock_colors": [3]  # Dark brownish rocks
	},
	CrystalType.RUBY: {
		"name": "Ruby",
		"color": Color(0.9, 0.1, 0.15, 0.7),  # Bright red with more transparency
		"spawn_chance": 0.05,  # 5% chance (very rare, cave-only)
		"growth_frequency": 0.005,  # Extremely rare - only in mountain caves
		"shape": CrystalShape.HEXAGONAL_PRISM,
		"preferred_rock_colors": [1, 3]  # Medium gray and dark brownish rocks
	},
	CrystalType.AMETHYST: {
		"name": "Amethyst",
		"color": Color(0.6, 0.3, 0.8, 0.65),  # Purple with more transparency
		"spawn_chance": 0.05,  # 5% chance (rare when spawning, appears in hidden locations)
		"growth_frequency": 0.07,  # Reduced overall frequency
		"shape": CrystalShape.CLUSTER,
		"preferred_rock_colors": [0, 2]  # Light gray and brownish gray rocks
	},
	CrystalType.SAPPHIRE: {
		"name": "Sapphire",
		"color": Color(0.15, 0.3, 0.85, 0.7),  # Deep blue with more transparency
		"spawn_chance": 0.05,  # 5% chance (very rare, cave-only)
		"growth_frequency": 0.005,  # Extremely rare - only in mountain caves
		"shape": CrystalShape.ELONGATED_PRISM,
		"preferred_rock_colors": [1, 2]  # Medium gray and brownish gray rocks
	}
}

## Get crystal type name
static func get_crystal_name(type: CrystalType) -> String:
	return crystal_configs[type]["name"]

## Get crystal color
static func get_crystal_color(type: CrystalType) -> Color:
	return crystal_configs[type]["color"]

## Get spawn chance for a crystal type
static func get_spawn_chance(type: CrystalType) -> float:
	return crystal_configs[type]["spawn_chance"]

## Get growth frequency for a crystal type
static func get_growth_frequency(type: CrystalType) -> float:
	return crystal_configs[type]["growth_frequency"]

## Get crystal shape for a crystal type
static func get_crystal_shape(type: CrystalType) -> CrystalShape:
	return crystal_configs[type]["shape"]

## Get preferred rock colors for a crystal type
static func get_preferred_rock_colors(type: CrystalType) -> Array:
	return crystal_configs[type]["preferred_rock_colors"]

## Check if crystal type can spawn on a given rock color index
static func can_spawn_on_rock_color(type: CrystalType, rock_color_index: int) -> bool:
	var preferred_colors = get_preferred_rock_colors(type)
	return rock_color_index in preferred_colors

## Select a random crystal type based on weighted probabilities and rock color
static func select_random_crystal_type(rng: RandomNumberGenerator, rock_color_index: int = -1) -> CrystalType:
	# If rock color is specified, filter types that can spawn on this rock
	var valid_types = []
	var total_weight = 0.0
	
	for type in CrystalType.values():
		# If no rock color specified or crystal can spawn on this rock color
		if rock_color_index == -1 or can_spawn_on_rock_color(type, rock_color_index):
			valid_types.append(type)
			total_weight += crystal_configs[type]["spawn_chance"]
	
	# If no valid types found (shouldn't happen), use all types
	if valid_types.is_empty():
		valid_types = CrystalType.values()
		total_weight = 0.0
		for type in valid_types:
			total_weight += crystal_configs[type]["spawn_chance"]
	
	var rand_value = rng.randf() * total_weight
	var current_weight = 0.0
	
	for type in valid_types:
		current_weight += crystal_configs[type]["spawn_chance"]
		if rand_value <= current_weight:
			return type
	
	# Fallback to first valid type
	return valid_types[0]

## Create a crystal mesh with shape based on crystal type
static func create_crystal_mesh(type: CrystalType, size_scale: float, seed_val: int = 0) -> ArrayMesh:
	var shape = get_crystal_shape(type)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	match shape:
		CrystalShape.HEXAGONAL_PRISM:
			return _create_hexagonal_crystal(type, size_scale, rng)
		CrystalShape.CUBIC:
			return _create_cubic_crystal(type, size_scale, rng)
		CrystalShape.ELONGATED_PRISM:
			return _create_elongated_crystal(type, size_scale, rng)
		CrystalShape.CLUSTER:
			return _create_cluster_crystal(type, size_scale, rng)
		_:
			return _create_hexagonal_crystal(type, size_scale, rng)

## Create a hexagonal prism crystal (original shape)
static func _create_hexagonal_crystal(type: CrystalType, size_scale: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Crystal dimensions (adjusted by size_scale)
	var base_radius = 0.15 * size_scale
	var height = rng.randf_range(0.4, 0.7) * size_scale
	var segments = 6  # Hexagonal crystal
	
	var color = get_crystal_color(type)
	var angle_step = TAU / segments
	
	# Create hexagonal crystal shape
	# Bottom vertices
	var bottom_verts = []
	for i in range(segments):
		var angle = i * angle_step
		var x = cos(angle) * base_radius
		var z = sin(angle) * base_radius
		bottom_verts.append(Vector3(x, 0, z))
	
	# Top is narrower (crystal point)
	var top_radius = base_radius * 0.3
	var top_verts = []
	for i in range(segments):
		var angle = i * angle_step + (angle_step * 0.5)  # Rotate top slightly
		var x = cos(angle) * top_radius
		var z = sin(angle) * top_radius
		top_verts.append(Vector3(x, height, z))
	
	# Apex point
	var apex = Vector3(0, height * 1.3, 0)
	
	# Add bottom faces (hexagon fan)
	var bottom_center = Vector3.ZERO
	for i in range(segments):
		var next_i = (i + 1) % segments
		surface_tool.set_color(color * 0.8)  # Slightly darker bottom
		surface_tool.add_vertex(bottom_center)
		surface_tool.add_vertex(bottom_verts[next_i])
		surface_tool.add_vertex(bottom_verts[i])
	
	# Add side faces (bottom to top hexagon)
	for i in range(segments):
		var next_i = (i + 1) % segments
		# Add color variation for crystal facets (brightness variation only, keeping color in valid range)
		var brightness = rng.randf_range(0.9, 1.0)
		var facet_color = Color(
			color.r * brightness,
			color.g * brightness,
			color.b * brightness,
			color.a
		)
		
		# Triangle 1
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(bottom_verts[i])
		surface_tool.add_vertex(bottom_verts[next_i])
		surface_tool.add_vertex(top_verts[i])
		
		# Triangle 2
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(bottom_verts[next_i])
		surface_tool.add_vertex(top_verts[next_i])
		surface_tool.add_vertex(top_verts[i])
	
	# Add top pyramid faces (from top hexagon to apex)
	for i in range(segments):
		var next_i = (i + 1) % segments
		# Slight brightness variation for top facets
		var brightness = rng.randf_range(0.95, 1.0)
		var facet_color = Color(
			color.r * brightness,
			color.g * brightness,
			color.b * brightness,
			color.a
		)
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(top_verts[i])
		surface_tool.add_vertex(top_verts[next_i])
		surface_tool.add_vertex(apex)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

## Create a cubic crystal (for garnets)
static func _create_cubic_crystal(type: CrystalType, size_scale: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var size = 0.2 * size_scale
	var color = get_crystal_color(type)
	
	# Define cube vertices (slightly irregular for natural look)
	var verts = [
		Vector3(-size, 0, -size), Vector3(size, 0, -size),
		Vector3(size, 0, size), Vector3(-size, 0, size),
		Vector3(-size * 0.9, size * 1.5, -size * 0.9), Vector3(size * 0.9, size * 1.5, -size * 0.9),
		Vector3(size * 0.9, size * 1.5, size * 0.9), Vector3(-size * 0.9, size * 1.5, size * 0.9)
	]
	
	# Cube faces (6 faces, 2 triangles each)
	var faces = [
		[0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6],  # Four side faces
		[3, 0, 4, 7], [4, 5, 6, 7], [0, 1, 2, 3]   # Two end faces (top and bottom)
	]
	
	for face in faces:
		var brightness = rng.randf_range(0.85, 1.0)
		var facet_color = Color(
			color.r * brightness,
			color.g * brightness,
			color.b * brightness,
			color.a
		)
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(verts[face[0]])
		surface_tool.add_vertex(verts[face[1]])
		surface_tool.add_vertex(verts[face[2]])
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(verts[face[0]])
		surface_tool.add_vertex(verts[face[2]])
		surface_tool.add_vertex(verts[face[3]])
	
	surface_tool.generate_normals()
	return surface_tool.commit()

## Create an elongated prism crystal (for emeralds and sapphires)
static func _create_elongated_crystal(type: CrystalType, size_scale: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var base_radius = 0.1 * size_scale
	var height = rng.randf_range(0.6, 1.0) * size_scale
	var segments = 6
	
	var color = get_crystal_color(type)
	var angle_step = TAU / segments
	
	# Bottom vertices
	var bottom_verts = []
	for i in range(segments):
		var angle = i * angle_step
		var x = cos(angle) * base_radius
		var z = sin(angle) * base_radius
		bottom_verts.append(Vector3(x, 0, z))
	
	# Top is very narrow (long thin crystal)
	var top_radius = base_radius * 0.2
	var top_verts = []
	for i in range(segments):
		var angle = i * angle_step + (angle_step * 0.3)
		var x = cos(angle) * top_radius
		var z = sin(angle) * top_radius
		top_verts.append(Vector3(x, height, z))
	
	# Apex point even higher
	var apex = Vector3(0, height * 1.4, 0)
	
	# Bottom faces
	var bottom_center = Vector3.ZERO
	for i in range(segments):
		var next_i = (i + 1) % segments
		surface_tool.set_color(color * 0.8)
		surface_tool.add_vertex(bottom_center)
		surface_tool.add_vertex(bottom_verts[next_i])
		surface_tool.add_vertex(bottom_verts[i])
	
	# Side faces
	for i in range(segments):
		var next_i = (i + 1) % segments
		var brightness = rng.randf_range(0.9, 1.0)
		var facet_color = Color(
			color.r * brightness,
			color.g * brightness,
			color.b * brightness,
			color.a
		)
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(bottom_verts[i])
		surface_tool.add_vertex(bottom_verts[next_i])
		surface_tool.add_vertex(top_verts[i])
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(bottom_verts[next_i])
		surface_tool.add_vertex(top_verts[next_i])
		surface_tool.add_vertex(top_verts[i])
	
	# Top pyramid faces
	for i in range(segments):
		var next_i = (i + 1) % segments
		var brightness = rng.randf_range(0.95, 1.0)
		var facet_color = Color(
			color.r * brightness,
			color.g * brightness,
			color.b * brightness,
			color.a
		)
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(top_verts[i])
		surface_tool.add_vertex(top_verts[next_i])
		surface_tool.add_vertex(apex)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

## Create a cluster crystal (multiple small points for amethysts)
static func _create_cluster_crystal(type: CrystalType, size_scale: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var color = get_crystal_color(type)
	var cluster_count = rng.randi_range(3, 5)
	
	# Create multiple small crystal points in a cluster
	for c in range(cluster_count):
		var offset_x = rng.randf_range(-0.08, 0.08) * size_scale
		var offset_z = rng.randf_range(-0.08, 0.08) * size_scale
		var point_height = rng.randf_range(0.3, 0.5) * size_scale
		var base_radius = 0.06 * size_scale
		var segments = 4  # Simple pyramid shape
		
		var angle_step = TAU / segments
		
		# Base vertices
		var base_verts = []
		for i in range(segments):
			var angle = i * angle_step + rng.randf_range(-0.1, 0.1)
			var x = cos(angle) * base_radius + offset_x
			var z = sin(angle) * base_radius + offset_z
			base_verts.append(Vector3(x, 0, z))
		
		# Apex of this point
		var apex = Vector3(offset_x, point_height, offset_z)
		
		# Create pyramid faces
		for i in range(segments):
			var next_i = (i + 1) % segments
			var brightness = rng.randf_range(0.85, 1.0)
			var facet_color = Color(
				color.r * brightness,
				color.g * brightness,
				color.b * brightness,
				color.a
			)
			
			surface_tool.set_color(facet_color)
			surface_tool.add_vertex(base_verts[i])
			surface_tool.add_vertex(base_verts[next_i])
			surface_tool.add_vertex(apex)
		
		# Base
		var base_center = Vector3(offset_x, 0, offset_z)
		for i in range(segments):
			var next_i = (i + 1) % segments
			surface_tool.set_color(color * 0.7)
			surface_tool.add_vertex(base_center)
			surface_tool.add_vertex(base_verts[next_i])
			surface_tool.add_vertex(base_verts[i])
	
	surface_tool.generate_normals()
	return surface_tool.commit()

## Create crystal material with transparency and shine
static func create_crystal_material(type: CrystalType) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	material.metallic = 0.2
	material.roughness = 0.2  # Shiny/reflective
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material.emission_enabled = true
	material.emission = get_crystal_color(type) * 0.3  # Slight glow
	return material
