extends Node3D
class_name Chunk

# Preload dependencies
const NarrativeMarker = preload("res://scripts/narrative_marker.gd")
const ClusterSystem = preload("res://scripts/cluster_system.gd")
const ProceduralModels = preload("res://scripts/procedural_models.gd")

# Chunk configuration
const CHUNK_SIZE = 32  # Size in world units
const RESOLUTION = 32  # Number of cells per side
const CELL_SIZE = CHUNK_SIZE / float(RESOLUTION)
const MAX_SLOPE_WALKABLE = 30.0  # degrees
const MIN_WALKABLE_PERCENTAGE = 0.8
const HEIGHT_RANGE = 10.0  # Maximum height variation from noise (±10 units)
const HEIGHT_COLOR_DIVISOR = HEIGHT_RANGE * 4.0  # Normalizes height to color range

# Chunk position in grid
var chunk_x: int = 0
var chunk_z: int = 0

# Terrain data
var heightmap: PackedFloat32Array = []
var walkable_map: PackedByteArray = []
var noise: FastNoiseLite
var biome_noise: FastNoiseLite  # Noise for regional biome variation
var seed_value: int = 0

# Metadata
var biome: String = "grassland"
var openness: float = 0.5  # 0 = closed/forest, 1 = open/plains
var landmark_type: String = ""  # e.g., "hill", "valley", ""

# Narrative markers
var narrative_markers: Array = []  # Array of NarrativeMarker
# Lake data
var has_lake: bool = false
var lake_center: Vector2 = Vector2.ZERO
var lake_radius: float = 0.0
var lake_depth: float = 1.5  # Knee-deep water depth

# Lake generation constants
const WATER_LEVEL_SAMPLE_RADIUS = 2
const LAKE_MESH_SEGMENTS = 16

# Mesh
var mesh_instance: MeshInstance3D
var water_mesh_instance: MeshInstance3D = null

# Cluster objects
var placed_objects: Array = []  # Array of MeshInstance3D for trees/buildings
var active_clusters: Array = []  # Clusters affecting this chunk

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
    _calculate_metadata()
    _generate_narrative_markers()
    _generate_lake_if_valley()
    _create_mesh()
    _place_cluster_objects()

func _setup_noise():
    noise = FastNoiseLite.new()
    noise.seed = seed_value
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = 0.02
    noise.fractal_octaves = 4
    noise.fractal_lacunarity = 2.0
    noise.fractal_gain = 0.5
    
    # Setup biome noise for regional variation
    biome_noise = FastNoiseLite.new()
    biome_noise.seed = seed_value + 1000
    biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
    biome_noise.frequency = 0.008  # Lower frequency for larger regions

func _generate_heightmap():
    heightmap.resize((RESOLUTION + 1) * (RESOLUTION + 1))
    
    for z in range(RESOLUTION + 1):
        for x in range(RESOLUTION + 1):
            var world_x = chunk_x * CHUNK_SIZE + x * CELL_SIZE
            var world_z = chunk_z * CHUNK_SIZE + z * CELL_SIZE
            
            # Get biome value to determine if this is a mountain or flat region
            var biome_value = biome_noise.get_noise_2d(world_x, world_z)
            
            # Mountains in regions where biome_value > 0.3
            # Flat areas in regions where biome_value < -0.2
            var height_multiplier = 10.0
            var height_offset = 0.0
            
            if biome_value > 0.3:
                # Mountain region - higher elevation and more variation
                height_multiplier = 20.0
                height_offset = 10.0
            elif biome_value < -0.2:
                # Flat region - lower elevation and less variation
                height_multiplier = 5.0
                height_offset = -3.0
            
            var height = noise.get_noise_2d(world_x, world_z) * height_multiplier + height_offset
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
            
            # Calculate average height for this cell
            var avg_height = (h00 + h10 + h01 + h11) / 4.0
            
            # Determine material color based on height (biome)
            var base_color: Color
            if avg_height > 8.0:
                # Mountain - stone/rocky gray color
                var height_factor = clamp((avg_height - 8.0) / 15.0, 0.0, 1.0)
                base_color = Color(0.5 + height_factor * 0.2, 0.5 + height_factor * 0.2, 0.55 + height_factor * 0.15)
            elif avg_height > 5.0:
                # Rocky hills - brown-gray mix
                var height_factor = clamp((avg_height - 5.0) / 3.0, 0.0, 1.0)
                base_color = Color(0.45 + height_factor * 0.1, 0.42 + height_factor * 0.08, 0.35 + height_factor * 0.1)
            else:
                # Grassland - green-brown earthy color
                var height_factor = clamp((avg_height + 5.0) / 10.0, 0.3, 0.8)
                base_color = Color(0.4 * height_factor, 0.5 * height_factor, 0.3 * height_factor)
            
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
    
    # Determine biome and landmark type based on height and variance
    if avg_height > 8.0:
        biome = "mountain"
        landmark_type = "mountain"
    elif avg_height > 5.0:
        biome = "rocky_hills"
        landmark_type = "hill"
    elif avg_height < -5.0:
        biome = "grassland"
        landmark_type = "valley"
    else:
        biome = "grassland"
        landmark_type = ""

func _generate_lake_if_valley():
    # Only generate lakes in valleys with some randomness
    if landmark_type != "valley":
        return
    
    # Use chunk position for random seed
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(Vector2i(chunk_x, chunk_z)) + seed_value
    
    # 30% chance of lake in valley
    if rng.randf() > 0.3:
        return
    
    has_lake = true
    
    # Lake is positioned at chunk center
    lake_center = Vector2(CHUNK_SIZE / 2.0, CHUNK_SIZE / 2.0)
    
    # Lake radius varies
    lake_radius = rng.randf_range(8.0, 14.0)
    
    # Create water mesh
    _create_water_mesh()

func _create_water_mesh():
    if not has_lake:
        return
    
    # Calculate water level (average height at center)
    var water_level = 0.0
    var sample_count = 0
    
    # Sample heights around lake center
    for i in range(-WATER_LEVEL_SAMPLE_RADIUS, WATER_LEVEL_SAMPLE_RADIUS + 1):
        for j in range(-WATER_LEVEL_SAMPLE_RADIUS, WATER_LEVEL_SAMPLE_RADIUS + 1):
            var sample_x = int(lake_center.x / CELL_SIZE) + i
            var sample_z = int(lake_center.y / CELL_SIZE) + j
            if sample_x >= 0 and sample_x <= RESOLUTION and sample_z >= 0 and sample_z <= RESOLUTION:
                water_level += heightmap[sample_z * (RESOLUTION + 1) + sample_x]
                sample_count += 1
    
    water_level /= sample_count
    
    # Create a circular water plane
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var angle_step = 2.0 * PI / LAKE_MESH_SEGMENTS
    
    # Center vertex
    var center_pos = Vector3(lake_center.x, water_level, lake_center.y)
    
    # Create triangular segments
    for i in range(LAKE_MESH_SEGMENTS):
        var angle1 = i * angle_step
        var angle2 = (i + 1) * angle_step
        
        var p1 = center_pos + Vector3(cos(angle1) * lake_radius, 0, sin(angle1) * lake_radius)
        var p2 = center_pos + Vector3(cos(angle2) * lake_radius, 0, sin(angle2) * lake_radius)
        
        # Water color (semi-transparent blue)
        var water_color = Color(0.2, 0.4, 0.8, 0.6)
        
        surface_tool.set_color(water_color)
        surface_tool.add_vertex(center_pos)
        surface_tool.add_vertex(p1)
        surface_tool.add_vertex(p2)
    
    surface_tool.generate_normals()
    
    var water_mesh = surface_tool.commit()
    water_mesh_instance = MeshInstance3D.new()
    water_mesh_instance.mesh = water_mesh
    
    # Create water material
    var water_material = StandardMaterial3D.new()
    water_material.vertex_color_use_as_albedo = true
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    water_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
    water_material.metallic = 0.0
    water_material.roughness = 0.1
    water_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
    
    water_mesh_instance.set_surface_override_material(0, water_material)
    add_child(water_mesh_instance)

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

func _generate_narrative_markers():
    # Generate markers based on chunk metadata
    # Performance-optimized: Only generate 1-3 markers per chunk based on importance
    
    var rng = RandomNumberGenerator.new()
    # Use efficient hash of chunk coordinates and seed
    rng.seed = hash(Vector2i(chunk_x, chunk_z)) ^ seed_value
    
    # Determine number of markers based on landmark and openness
    var marker_count = 0
    if landmark_type != "":
        marker_count = 2  # Landmarks are important, get 2 markers
    elif openness > 0.7:
        marker_count = 1  # Open areas get 1 marker (discovery point)
    elif rng.randf() > 0.7:
        marker_count = 1  # 30% chance for regular chunks
    
    for i in range(marker_count):
        var marker = _create_marker_for_chunk(i, rng)
        if marker:
            narrative_markers.append(marker)

func _create_marker_for_chunk(index: int, rng: RandomNumberGenerator) -> NarrativeMarker:
    # Find a suitable walkable position for the marker
    var attempts = 0
    var max_attempts = 10
    var marker_pos: Vector3
    
    while attempts < max_attempts:
        var rand_x = rng.randi_range(2, RESOLUTION - 3)
        var rand_z = rng.randi_range(2, RESOLUTION - 3)
        
        # Check if position is walkable
        if walkable_map[rand_z * RESOLUTION + rand_x] == 1:
            var world_x = chunk_x * CHUNK_SIZE + rand_x * CELL_SIZE
            var world_z = chunk_z * CHUNK_SIZE + rand_z * CELL_SIZE
            var height = get_height_at_world_pos(world_x, world_z)
            marker_pos = Vector3(world_x, height, world_z)
            break
        attempts += 1
    
    if attempts >= max_attempts:
        return null  # Couldn't find walkable position
    
    # Determine marker type based on chunk metadata
    var marker_type: String
    var importance: float
    
    if landmark_type == "hill":
        marker_type = "landmark"
        importance = 0.8
    elif landmark_type == "valley":
        marker_type = "discovery"
        importance = 0.7
    elif openness > 0.7:
        marker_type = "encounter"
        importance = 0.6
    else:
        marker_type = "discovery"
        importance = 0.5
    
    # Create marker without fixed story text
    var marker_id = "marker_%d_%d_%d" % [chunk_x, chunk_z, index]
    var chunk_pos = Vector2i(chunk_x, chunk_z)
    var marker = NarrativeMarker.new(marker_id, chunk_pos, marker_pos, marker_type)
    marker.importance = importance
    
    # Add flexible metadata instead of fixed story
    marker.metadata = {
        "biome": biome,
        "landmark_type": landmark_type,
        "openness": openness,
        "chunk_seed": seed_value
    }
    
    return marker

func get_narrative_markers() -> Array:
    return narrative_markers

func get_terrain_material_at_world_pos(world_x: float, world_z: float) -> String:
    # Get height at position to determine material type
    var height = get_height_at_world_pos(world_x, world_z)
    
    if height > 8.0:
        return "stone"
    elif height > 5.0:
        return "rock"
    else:
        return "grass"

func get_water_depth_at_local_pos(local_x: float, local_z: float) -> float:
    # Check if position is in lake
    if not has_lake:
        return 0.0
    
    var dist_to_center = Vector2(local_x, local_z).distance_to(lake_center)
    
    # Outside lake
    if dist_to_center > lake_radius:
        return 0.0
    
    # Water gets deeper towards center (knee-deep at center)
    var depth_factor = 1.0 - (dist_to_center / lake_radius)
    return depth_factor * lake_depth

func get_slope_at_world_pos(world_x: float, world_z: float) -> float:
    # Convert world position to local chunk position
    var local_x = world_x - chunk_x * CHUNK_SIZE
    var local_z = world_z - chunk_z * CHUNK_SIZE
    
    # Convert to cell coordinates
    var cell_x = local_x / CELL_SIZE
    var cell_z = local_z / CELL_SIZE
    
    # Clamp to valid cell range that allows accessing x+1 and z+1
    var x = int(clamp(cell_x, 0, RESOLUTION - 1))
    var z = int(clamp(cell_z, 0, RESOLUTION - 1))
    
    # Ensure we can safely access x+1 and z+1
    # Note: heightmap is (RESOLUTION+1) x (RESOLUTION+1), so RESOLUTION is a valid index
    var x1 = min(x + 1, RESOLUTION)
    var z1 = min(z + 1, RESOLUTION)
    
    # Get heights of the 4 corners of this cell
    var h00 = heightmap[z * (RESOLUTION + 1) + x]
    var h10 = heightmap[z * (RESOLUTION + 1) + x1]
    var h01 = heightmap[z1 * (RESOLUTION + 1) + x]
    var h11 = heightmap[z1 * (RESOLUTION + 1) + x1]
    
    # Calculate slope using the maximum height difference
    var max_height_diff = max(max(abs(h10 - h00), abs(h01 - h00)), abs(h11 - h00))
    var slope_rad = atan(max_height_diff / CELL_SIZE)
    return rad_to_deg(slope_rad)

func get_slope_gradient_at_world_pos(world_x: float, world_z: float) -> Vector3:
    # Returns the gradient vector (direction of steepest ascent) at the given position
    # Convert world position to local chunk position
    var local_x = world_x - chunk_x * CHUNK_SIZE
    var local_z = world_z - chunk_z * CHUNK_SIZE
    
    # Convert to cell coordinates
    var cell_x = local_x / CELL_SIZE
    var cell_z = local_z / CELL_SIZE
    
    # Clamp to valid cell range
    var x = int(clamp(cell_x, 0, RESOLUTION - 1))
    var z = int(clamp(cell_z, 0, RESOLUTION - 1))
    
    # Ensure we can safely access x+1 and z+1
    var x1 = min(x + 1, RESOLUTION)
    var z1 = min(z + 1, RESOLUTION)
    
    # Get heights of all four cell corners for more robust calculation
    var h00 = heightmap[z * (RESOLUTION + 1) + x]
    var h10 = heightmap[z * (RESOLUTION + 1) + x1]
    var h01 = heightmap[z1 * (RESOLUTION + 1) + x]
    var h11 = heightmap[z1 * (RESOLUTION + 1) + x1]
    
    # Calculate gradient using proper central differences for better accuracy
    # This averages the height differences across both axes for a more robust gradient
    var dx = (h10 + h11 - h00 - h01) / (2.0 * CELL_SIZE)  # average height change in x direction
    var dz = (h01 + h11 - h00 - h10) / (2.0 * CELL_SIZE)  # average height change in z direction
    
    # Return gradient vector (direction of steepest ascent)
    # In 3D space: gradient points uphill
    return Vector3(dx, 0, dz)

## Place trees and buildings based on cluster system
func _place_cluster_objects():
# Get clusters affecting this chunk
var chunk_pos = Vector2i(chunk_x, chunk_z)
active_clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, seed_value)

if active_clusters.is_empty():
return

# Place objects for each cluster
for cluster in active_clusters:
if cluster.type == ClusterSystem.ClusterType.FOREST:
_place_forest_objects(cluster)
elif cluster.type == ClusterSystem.ClusterType.SETTLEMENT:
_place_settlement_objects(cluster)

## Place trees for a forest cluster
func _place_forest_objects(cluster: ClusterSystem.ClusterData):
var rng = RandomNumberGenerator.new()
rng.seed = cluster.seed_value ^ hash(Vector2i(chunk_x, chunk_z))

# Calculate how many trees to place based on cluster density and influence
var chunk_area = CHUNK_SIZE * CHUNK_SIZE
var avg_influence = 0.0
var sample_count = 0

# Sample influence at a grid of points
for x in range(0, int(CHUNK_SIZE), 4):
for z in range(0, int(CHUNK_SIZE), 4):
var world_pos = Vector2(chunk_x * CHUNK_SIZE + x, chunk_z * CHUNK_SIZE + z)
var influence = ClusterSystem.get_cluster_influence_at_pos(world_pos, cluster)
avg_influence += influence
sample_count += 1

avg_influence /= sample_count
var tree_count = int(chunk_area * cluster.density * avg_influence * 0.02)  # Reduced for performance

# Place trees
for i in range(tree_count):
var local_x = rng.randf_range(1.0, CHUNK_SIZE - 1.0)
var local_z = rng.randf_range(1.0, CHUNK_SIZE - 1.0)
var world_x = chunk_x * CHUNK_SIZE + local_x
var world_z = chunk_z * CHUNK_SIZE + local_z

# Check if position is influenced by cluster
var influence = ClusterSystem.get_cluster_influence_at_pos(Vector2(world_x, world_z), cluster)
if influence < 0.1:
continue

# Check if on walkable terrain
var cell_x = int(local_x / CELL_SIZE)
var cell_z = int(local_z / CELL_SIZE)
if cell_x >= 0 and cell_x < RESOLUTION and cell_z >= 0 and cell_z < RESOLUTION:
if walkable_map[cell_z * RESOLUTION + cell_x] != 1:
continue

# Get terrain height
var height = get_height_at_world_pos(world_x, world_z)

# Skip if in lake
if has_lake:
var dist_to_lake = Vector2(local_x, local_z).distance_to(lake_center)
if dist_to_lake < lake_radius:
continue

# Create tree instance
var tree_instance = MeshInstance3D.new()
tree_instance.mesh = ProceduralModels.create_tree_mesh(rng.randi())
tree_instance.material_override = ProceduralModels.create_tree_material()
tree_instance.position = Vector3(local_x, height, local_z)
tree_instance.rotation.y = rng.randf_range(0, TAU)  # Random rotation
tree_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

add_child(tree_instance)
placed_objects.append(tree_instance)

## Place buildings for a settlement cluster
func _place_settlement_objects(cluster: ClusterSystem.ClusterData):
var rng = RandomNumberGenerator.new()
rng.seed = cluster.seed_value ^ hash(Vector2i(chunk_x, chunk_z))

# Calculate how many buildings to place
var chunk_area = CHUNK_SIZE * CHUNK_SIZE
var avg_influence = 0.0
var sample_count = 0

for x in range(0, int(CHUNK_SIZE), 4):
for z in range(0, int(CHUNK_SIZE), 4):
var world_pos = Vector2(chunk_x * CHUNK_SIZE + x, chunk_z * CHUNK_SIZE + z)
var influence = ClusterSystem.get_cluster_influence_at_pos(world_pos, cluster)
avg_influence += influence
sample_count += 1

avg_influence /= sample_count
var building_count = int(chunk_area * cluster.density * avg_influence * 0.015)  # Fewer buildings than trees

# Place buildings
for i in range(building_count):
var local_x = rng.randf_range(3.0, CHUNK_SIZE - 3.0)
var local_z = rng.randf_range(3.0, CHUNK_SIZE - 3.0)
var world_x = chunk_x * CHUNK_SIZE + local_x
var world_z = chunk_z * CHUNK_SIZE + local_z

# Check cluster influence
var influence = ClusterSystem.get_cluster_influence_at_pos(Vector2(world_x, world_z), cluster)
if influence < 0.2:  # Higher threshold for buildings
continue

# Check if on walkable, relatively flat terrain
var cell_x = int(local_x / CELL_SIZE)
var cell_z = int(local_z / CELL_SIZE)
if cell_x >= 0 and cell_x < RESOLUTION and cell_z >= 0 and cell_z < RESOLUTION:
if walkable_map[cell_z * RESOLUTION + cell_x] != 1:
continue

# Check slope - buildings need flatter ground
var slope = _calculate_slope(cell_x, cell_z)
if slope > 15.0:  # Max 15 degrees for buildings
continue

# Get terrain height
var height = get_height_at_world_pos(world_x, world_z)

# Skip if in lake
if has_lake:
var dist_to_lake = Vector2(local_x, local_z).distance_to(lake_center)
if dist_to_lake < lake_radius + 2.0:  # Extra margin for buildings
continue

# Create building instance
var building_instance = MeshInstance3D.new()
building_instance.mesh = ProceduralModels.create_building_mesh(rng.randi())
building_instance.material_override = ProceduralModels.create_building_material()
building_instance.position = Vector3(local_x, height, local_z)
building_instance.rotation.y = rng.randf_range(0, TAU)  # Random rotation
building_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

add_child(building_instance)
placed_objects.append(building_instance)
