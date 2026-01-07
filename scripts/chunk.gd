extends Node3D
class_name Chunk

# Chunk configuration
const CHUNK_SIZE = 32  # Size in world units
const RESOLUTION = 32  # Number of cells per side
const CELL_SIZE = CHUNK_SIZE / float(RESOLUTION)
const MAX_SLOPE_WALKABLE = 30.0  # degrees
const MIN_WALKABLE_PERCENTAGE = 0.8

# Chunk position in grid
var chunk_x: int = 0
var chunk_z: int = 0

# Terrain data
var heightmap: PackedFloat32Array = []
var walkable_map: PackedByteArray = []
var noise: FastNoiseLite
var seed_value: int = 0

# Metadata
var biome: String = "grassland"
var openness: float = 0.5  # 0 = closed/forest, 1 = open/plains
var landmark_type: String = ""  # e.g., "hill", "valley", ""

# Mesh
var mesh_instance: MeshInstance3D

func _init(x: int, z: int, world_seed: int):
	chunk_x = x
	chunk_z = z
	seed_value = world_seed
	name = "Chunk_%d_%d" % [x, z]

func generate():
	_setup_noise()
	_generate_heightmap()
	_calculate_walkability()
	_ensure_walkable_area()
	_create_mesh()
	_calculate_metadata()

func _setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

func _generate_heightmap():
	heightmap.resize((RESOLUTION + 1) * (RESOLUTION + 1))
	
	for z in range(RESOLUTION + 1):
		for x in range(RESOLUTION + 1):
			var world_x = chunk_x * CHUNK_SIZE + x * CELL_SIZE
			var world_z = chunk_z * CHUNK_SIZE + z * CELL_SIZE
			
			var height = noise.get_noise_2d(world_x, world_z) * 10.0
			heightmap[z * (RESOLUTION + 1) + x] = height

func _calculate_walkability():
	walkable_map.resize(RESOLUTION * RESOLUTION)
	
	for z in range(RESOLUTION):
		for x in range(RESOLUTION):
			var slope = _calculate_slope(x, z)
			var walkable = slope <= MAX_SLOPE_WALKABLE
			walkable_map[z * RESOLUTION + x] = 1 if walkable else 0

func _calculate_slope(x: int, z: int) -> float:
	# Get heights of the 4 corners of this cell
	var h00 = heightmap[z * (RESOLUTION + 1) + x]
	var h10 = heightmap[z * (RESOLUTION + 1) + (x + 1)]
	var h01 = heightmap[(z + 1) * (RESOLUTION + 1) + x]
	var h11 = heightmap[(z + 1) * (RESOLUTION + 1) + (x + 1)]
	
	# Calculate slope using the maximum height difference
	var max_height_diff = max(max(abs(h10 - h00), abs(h01 - h00)), abs(h11 - h00))
	var slope_rad = atan(max_height_diff / CELL_SIZE)
	return rad_to_deg(slope_rad)

func _ensure_walkable_area():
	var walkable_count = 0
	for i in range(walkable_map.size()):
		if walkable_map[i] == 1:
			walkable_count += 1
	
	var walkable_percentage = float(walkable_count) / float(walkable_map.size())
	
	if walkable_percentage < MIN_WALKABLE_PERCENTAGE:
		_smooth_terrain()

func _smooth_terrain():
	# Simple terrain smoothing: average heights with neighbors
	var new_heightmap = heightmap.duplicate()
	
	for z in range(1, RESOLUTION):
		for x in range(1, RESOLUTION):
			var idx = z * (RESOLUTION + 1) + x
			var sum = heightmap[idx]
			var count = 1
			
			# Average with 8 neighbors
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dz == 0:
						continue
					var nx = x + dx
					var nz = z + dz
					if nx >= 0 and nx <= RESOLUTION and nz >= 0 and nz <= RESOLUTION:
						sum += heightmap[nz * (RESOLUTION + 1) + nx]
						count += 1
			
			new_heightmap[idx] = sum / count
	
	heightmap = new_heightmap
	_calculate_walkability()

func _create_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate vertices and triangles
	for z in range(RESOLUTION):
		for x in range(RESOLUTION):
			var x0 = x * CELL_SIZE
			var x1 = (x + 1) * CELL_SIZE
			var z0 = z * CELL_SIZE
			var z1 = (z + 1) * CELL_SIZE
			
			var h00 = heightmap[z * (RESOLUTION + 1) + x]
			var h10 = heightmap[z * (RESOLUTION + 1) + (x + 1)]
			var h01 = heightmap[(z + 1) * (RESOLUTION + 1) + x]
			var h11 = heightmap[(z + 1) * (RESOLUTION + 1) + (x + 1)]
			
			# Use subtle color variation based on height for terrain depth
			# Higher areas are lighter, lower areas are darker
			var height_factor = (h00 + h10 + h01 + h11) / 40.0 + 0.5  # Normalize around 0.5
			height_factor = clamp(height_factor, 0.3, 0.8)
			
			# Base terrain color (earthy green-brown)
			var base_color = Color(0.4 * height_factor, 0.5 * height_factor, 0.3 * height_factor)
			
			# Optional: Tint non-walkable areas slightly (for subtle indication)
			var is_walkable = walkable_map[z * RESOLUTION + x] == 1
			if not is_walkable:
				base_color = base_color.lerp(Color(0.5, 0.4, 0.3), 0.2)  # Subtle brownish tint
			
			# First triangle
			surface_tool.set_color(base_color)
			surface_tool.add_vertex(Vector3(x0, h00, z0))
			surface_tool.add_vertex(Vector3(x1, h10, z0))
			surface_tool.add_vertex(Vector3(x0, h01, z1))
			
			# Second triangle
			surface_tool.add_vertex(Vector3(x1, h10, z0))
			surface_tool.add_vertex(Vector3(x1, h11, z1))
			surface_tool.add_vertex(Vector3(x0, h01, z1))
	
	surface_tool.generate_normals()
	
	var mesh = surface_tool.commit()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Create terrain material with proper shading and shadow receiving
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.roughness = 0.9
	# Enable shadow receiving to show terrain depth
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)

func _calculate_metadata():
	# Calculate openness based on average height variance
	var avg_height = 0.0
	for h in heightmap:
		avg_height += h
	avg_height /= heightmap.size()
	
	var variance = 0.0
	for h in heightmap:
		variance += (h - avg_height) * (h - avg_height)
	variance /= heightmap.size()
	
	# More variance = less open (mountains/hills), less variance = more open (plains)
	openness = clamp(1.0 - (variance / 10.0), 0.0, 1.0)
	
	# Determine landmark type based on height and variance
	if avg_height > 5.0:
		landmark_type = "hill"
	elif avg_height < -5.0:
		landmark_type = "valley"
	else:
		landmark_type = ""

func get_height_at_world_pos(world_x: float, world_z: float) -> float:
	# Convert world position to local chunk position
	var local_x = world_x - chunk_x * CHUNK_SIZE
	var local_z = world_z - chunk_z * CHUNK_SIZE
	
	# Convert to cell coordinates
	var cell_x = local_x / CELL_SIZE
	var cell_z = local_z / CELL_SIZE
	
	# Clamp to chunk bounds
	cell_x = clamp(cell_x, 0, RESOLUTION)
	cell_z = clamp(cell_z, 0, RESOLUTION)
	
	# Get interpolated height
	var x0 = int(cell_x)
	var z0 = int(cell_z)
	var x1 = min(x0 + 1, RESOLUTION)
	var z1 = min(z0 + 1, RESOLUTION)
	
	var fx = cell_x - x0
	var fz = cell_z - z0
	
	var h00 = heightmap[z0 * (RESOLUTION + 1) + x0]
	var h10 = heightmap[z0 * (RESOLUTION + 1) + x1]
	var h01 = heightmap[z1 * (RESOLUTION + 1) + x0]
	var h11 = heightmap[z1 * (RESOLUTION + 1) + x1]
	
	var h0 = lerp(h00, h10, fx)
	var h1 = lerp(h01, h11, fx)
	
	return lerp(h0, h1, fz)

func check_connectivity_to_neighbor(direction: Vector2i) -> bool:
	# Simple flood-fill check for connectivity
	# For now, we'll assume connectivity if there's sufficient walkable area
	var walkable_count = 0
	for i in range(walkable_map.size()):
		if walkable_map[i] == 1:
			walkable_count += 1
	
	return float(walkable_count) / float(walkable_map.size()) >= MIN_WALKABLE_PERCENTAGE

func blend_edges_with_neighbor(neighbor_chunk):
	# Blend edge heights with neighbor to avoid seams
	if not neighbor_chunk:
		return
	
	# This would be implemented based on which edge to blend
	pass
