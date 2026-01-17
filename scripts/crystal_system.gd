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

# Crystal type configurations
static var crystal_configs = {
	CrystalType.MOUNTAIN_CRYSTAL: {
		"name": "Mountain Crystal",
		"color": Color(0.9, 0.95, 1.0, 0.85),  # Clear/white with transparency
		"spawn_chance": 0.35,  # 35% chance when crystal spawns
		"growth_frequency": 0.4  # How often this type grows on rocks
	},
	CrystalType.EMERALD: {
		"name": "Emerald",
		"color": Color(0.2, 0.8, 0.3, 0.9),  # Green
		"spawn_chance": 0.25,  # 25% chance
		"growth_frequency": 0.25
	},
	CrystalType.GARNET: {
		"name": "Garnet",
		"color": Color(0.7, 0.2, 0.2, 0.9),  # Dark red
		"spawn_chance": 0.20,  # 20% chance
		"growth_frequency": 0.20
	},
	CrystalType.RUBY: {
		"name": "Ruby",
		"color": Color(0.9, 0.1, 0.15, 0.95),  # Bright red
		"spawn_chance": 0.08,  # 8% chance (rare)
		"growth_frequency": 0.05
	},
	CrystalType.AMETHYST: {
		"name": "Amethyst",
		"color": Color(0.6, 0.3, 0.8, 0.9),  # Purple
		"spawn_chance": 0.20,  # 20% chance
		"growth_frequency": 0.18
	},
	CrystalType.SAPPHIRE: {
		"name": "Sapphire",
		"color": Color(0.15, 0.3, 0.85, 0.95),  # Deep blue
		"spawn_chance": 0.07,  # 7% chance (rare)
		"growth_frequency": 0.07
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

## Select a random crystal type based on weighted probabilities
static func select_random_crystal_type(rng: RandomNumberGenerator) -> CrystalType:
	var total_weight = 0.0
	for type in CrystalType.values():
		total_weight += crystal_configs[type]["spawn_chance"]
	
	var rand_value = rng.randf() * total_weight
	var current_weight = 0.0
	
	for type in CrystalType.values():
		current_weight += crystal_configs[type]["spawn_chance"]
		if rand_value <= current_weight:
			return type
	
	# Fallback to mountain crystal
	return CrystalType.MOUNTAIN_CRYSTAL

## Create a crystal mesh (hexagonal prism shape)
static func create_crystal_mesh(type: CrystalType, size_scale: float, seed_val: int = 0) -> ArrayMesh:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
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
		# Add color variation for crystal facets
		var facet_color = color * rng.randf_range(0.9, 1.1)
		
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
		var facet_color = color * rng.randf_range(0.95, 1.15)
		
		surface_tool.set_color(facet_color)
		surface_tool.add_vertex(top_verts[i])
		surface_tool.add_vertex(top_verts[next_i])
		surface_tool.add_vertex(apex)
	
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
