extends Node3D
class_name Chunk

## Procedural terrain chunk with walkability analysis and content generation
## 
## This class represents a single 32x32 world unit chunk of procedural terrain.
## It generates heightmaps, calculates walkability, places objects, and creates
## visual meshes optimized for mobile rendering.
##
## Key features:
## - Seed-based reproducible terrain generation
## - Automatic walkability analysis (80% minimum)
## - Edge blending with neighboring chunks
## - Dynamic object placement (rocks, trees, buildings)
## - Path generation and rendering
## - Lake generation in valley biomes

# ============================================================================
# DEPENDENCIES
# ============================================================================

# Preload dependencies
const NarrativeMarker = preload("res://scripts/narrative_marker.gd")
const ClusterSystem = preload("res://scripts/cluster_system.gd")
const ProceduralModels = preload("res://scripts/procedural_models.gd")
const PathSystem = preload("res://scripts/path_system.gd")
const CrystalSystem = preload("res://scripts/crystal_system.gd")

# ============================================================================
# CONFIGURATION CONSTANTS
# ============================================================================

# Chunk configuration
const CHUNK_SIZE = 32  # Size in world units
const RESOLUTION = 32  # Number of cells per side
const CELL_SIZE = CHUNK_SIZE / float(RESOLUTION)
const MAX_SLOPE_WALKABLE = 30.0  # degrees
const MIN_WALKABLE_PERCENTAGE = 0.8
const HEIGHT_RANGE = 10.0  # Maximum height variation from noise (±10 units)
const HEIGHT_COLOR_DIVISOR = HEIGHT_RANGE * 4.0  # Normalizes height to color range
const PATH_ELEVATION_OFFSET = 0.01  # Minimal offset to prevent z-fighting, path as ground texture

# Path colors - subtle earth tones as ground texture variation
const BRANCH_PATH_COLOR = Color(0.52, 0.48, 0.38)  # Subtle dirt path
const MAIN_PATH_COLOR = Color(0.55, 0.50, 0.40)  # Slightly worn earth
const ENDPOINT_PATH_COLOR = Color(0.58, 0.52, 0.42)  # Well-traveled ground

# Rock placement constants
const ROCK_SEED_OFFSET = 12345  # Offset for rock placement seed differentiation
const ROCK_COUNT_MOUNTAIN_MIN = 8
const ROCK_COUNT_MOUNTAIN_MAX = 15
const ROCK_COUNT_ROCKY_MIN = 5
const ROCK_COUNT_ROCKY_MAX = 10
const ROCK_COUNT_GRASSLAND_MIN = 2
const ROCK_COUNT_GRASSLAND_MAX = 5

# Crystal placement constants
const CRYSTAL_SEED_OFFSET = 54321  # Offset for crystal placement seed
const CRYSTAL_SPAWN_CHANCE = 0.20  # 20% chance a rock will have crystals (reduced from 35%)
const CRYSTALS_PER_ROCK_MIN = 1
const CRYSTALS_PER_ROCK_MAX = 2  # Reduced from 3 for rarer crystals

# Path bush placement constants
const BUSH_SEED_OFFSET = 99999  # Offset for path bush placement seed differentiation

# Ocean and lighthouse constants
const OCEAN_LEVEL = -8.0  # Elevation threshold for ocean biome
const LIGHTHOUSE_SEED_OFFSET = 77777  # Offset for lighthouse placement seed
const LIGHTHOUSE_SPACING = 80.0  # Distance between lighthouses along coastline

# ============================================================================
# STATE VARIABLES
# ============================================================================

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

# Ocean data
var is_ocean: bool = false
var ocean_water_level: float = OCEAN_LEVEL

# Lighthouse data
var placed_lighthouses: Array = []  # Array of lighthouse MeshInstance3D

# Lake generation constants
const WATER_LEVEL_SAMPLE_RADIUS = 2
const LAKE_MESH_SEGMENTS = 16

# Mesh
var mesh_instance: MeshInstance3D
var water_mesh_instance: MeshInstance3D = null  # Used for lakes
var ocean_mesh_instance: MeshInstance3D = null  # Used for ocean

# Cluster objects
var placed_objects: Array = []  # Array of MeshInstance3D for trees/buildings
var active_clusters: Array = []  # Clusters affecting this chunk

# Crystal data
var placed_crystals: Array = []  # Array of crystal MeshInstance3D with metadata

# Path data
var path_segments: Array = []  # Array of PathSystem.PathSegment
var path_mesh_instance: MeshInstance3D = null

# Wind sound data
var wind_sound_player: AudioStreamPlayer3D = null  # Wind ambient sound for mountain regions

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(x: int, z: int, world_seed: int):
    chunk_x = x
    chunk_z = z
    seed_value = world_seed
    name = "Chunk_%d_%d" % [x, z]

## Generates all terrain data and visuals for this chunk
## This is the main entry point called after chunk creation
## Pipeline: noise → heightmap → walkability → metadata → markers → lake → ocean → mesh → objects → paths → lighthouses
func generate() -> void:
    _setup_noise()
    _generate_heightmap()
    _calculate_walkability()
    _ensure_walkable_area()
    _calculate_metadata()
    _generate_narrative_markers()
    _generate_lake_if_valley()
    _generate_ocean_if_low()
    _create_mesh()
    _place_rocks()  # Add rocks to terrain
    _place_cluster_objects()
    _generate_paths()
    _place_lighthouses_if_coastal()
    _setup_wind_sound()  # Add wind ambient sound for mountain regions

# ============================================================================
# TERRAIN GENERATION
# ============================================================================

func _setup_noise() -> void:
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

func _generate_heightmap() -> void:
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

func _calculate_walkability() -> void:
    # Initialize walkability map - 1D array indexed by [z * RESOLUTION + x]
    walkable_map.resize(RESOLUTION * RESOLUTION)
    
    # Calculate slope for each cell and mark as walkable if <= 30 degrees
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

func _ensure_walkable_area() -> void:
    # Count walkable cells to ensure minimum 80% walkability requirement
    var walkable_count = 0
    for i in range(walkable_map.size()):
        if walkable_map[i] == 1:
            walkable_count += 1
    
    var walkable_percentage = float(walkable_count) / float(walkable_map.size())
    
    # If below threshold, smooth terrain and recalculate walkability
    if walkable_percentage < MIN_WALKABLE_PERCENTAGE:
        _smooth_terrain()

func _smooth_terrain() -> void:
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

# ============================================================================
# MESH GENERATION
# ============================================================================

func _create_mesh() -> void:
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Pre-calculate forest influences for this chunk to darken forest floor
    # Note: This is a one-time calculation during chunk generation (not per-frame)
    # Performance: O(RESOLUTION² × num_clusters) but only executed once on chunk load
    var chunk_pos = Vector2i(chunk_x, chunk_z)
    var forest_clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, seed_value)
    var forest_influence_map = []
    forest_influence_map.resize(RESOLUTION * RESOLUTION)
    
    # Calculate forest influence for each cell
    for z in range(RESOLUTION):
        for x in range(RESOLUTION):
            var cell_center_x = chunk_x * CHUNK_SIZE + (x + 0.5) * CELL_SIZE
            var cell_center_z = chunk_z * CHUNK_SIZE + (z + 0.5) * CELL_SIZE
            var world_pos = Vector2(cell_center_x, cell_center_z)
            
            var max_forest_influence = 0.0
            for cluster in forest_clusters:
                if cluster.type == ClusterSystem.ClusterType.FOREST:
                    var influence = ClusterSystem.get_cluster_influence_at_pos(world_pos, cluster)
                    max_forest_influence = max(max_forest_influence, influence)
            
            forest_influence_map[z * RESOLUTION + x] = max_forest_influence
    
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
            if avg_height <= OCEAN_LEVEL:
                # Ocean floor - sandy/rocky seabed
                base_color = Color(0.6, 0.55, 0.4)  # Sandy color for ocean floor
            elif avg_height > 8.0:
                # Mountain - stone/rocky gray color transitioning to snow at high elevations
                var height_factor = clamp((avg_height - 8.0) / 15.0, 0.0, 1.0)
                var rocky_color = Color(0.5 + height_factor * 0.2, 0.5 + height_factor * 0.2, 0.55 + height_factor * 0.15)
                
                # Add snow coverage at highest elevations (>12 units)
                if avg_height > 12.0:
                    var snow_factor = clamp((avg_height - 12.0) / 8.0, 0.0, 1.0)
                    var snow_color = Color(0.95, 0.95, 0.98)  # Slightly bluish white snow
                    base_color = rocky_color.lerp(snow_color, snow_factor)
                else:
                    base_color = rocky_color
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
            
            # Darken ground in forest areas
            var forest_influence = forest_influence_map[z * RESOLUTION + x]
            if forest_influence > 0.1:
                # Make ground darker and more brown/earthy in forests
                var dark_forest_color = Color(0.25, 0.2, 0.15)  # Dark brown forest floor
                base_color = base_color.lerp(dark_forest_color, forest_influence * 0.5)
            
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

func _calculate_metadata() -> void:
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
    if avg_height <= OCEAN_LEVEL:
        biome = "ocean"
        landmark_type = "ocean"
        is_ocean = true
    elif avg_height > 8.0:
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

func _generate_lake_if_valley() -> void:
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

func _create_water_mesh() -> void:
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

func blend_edges_with_neighbor(neighbor_chunk) -> void:
    # Blend edge heights with neighbor to avoid seams
    if not neighbor_chunk:
        return
    
    # This would be implemented based on which edge to blend
    pass

func _generate_narrative_markers() -> void:
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

## Place rocks on terrain for decoration
func _place_rocks() -> void:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_value ^ hash(Vector2i(chunk_x, chunk_z)) ^ ROCK_SEED_OFFSET
    
    # Determine rock count based on biome - more rocks in rocky/mountain areas
    var rock_count = 0
    if biome == "mountain":
        rock_count = rng.randi_range(ROCK_COUNT_MOUNTAIN_MIN, ROCK_COUNT_MOUNTAIN_MAX)
    elif biome == "rocky_hills":
        rock_count = rng.randi_range(ROCK_COUNT_ROCKY_MIN, ROCK_COUNT_ROCKY_MAX)
    else:
        rock_count = rng.randi_range(ROCK_COUNT_GRASSLAND_MIN, ROCK_COUNT_GRASSLAND_MAX)
    
    # Place rocks
    for i in range(rock_count):
        var local_x = rng.randf_range(1.0, CHUNK_SIZE - 1.0)
        var local_z = rng.randf_range(1.0, CHUNK_SIZE - 1.0)
        var world_x = chunk_x * CHUNK_SIZE + local_x
        var world_z = chunk_z * CHUNK_SIZE + local_z
        
        # Get terrain height
        var height = get_height_at_world_pos(world_x, world_z)
        
        # Skip if in lake
        if has_lake:
            var dist_to_lake = Vector2(local_x, local_z).distance_to(lake_center)
            if dist_to_lake < lake_radius + 1.0:
                continue
        
        # Create rock instance
        var rock_seed = rng.randi()
        var rock_instance = MeshInstance3D.new()
        rock_instance.mesh = ProceduralModels.create_rock_mesh(rock_seed)
        rock_instance.material_override = ProceduralModels.create_rock_material()
        rock_instance.position = Vector3(local_x, height, local_z)
        rock_instance.rotation.y = rng.randf_range(0, TAU)  # Random rotation
        # Random tilt for more natural look
        rock_instance.rotation.x = rng.randf_range(-0.1, 0.1)
        rock_instance.rotation.z = rng.randf_range(-0.1, 0.1)
        rock_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        
        # Store rock color index for crystal compatibility
        var rock_rng = RandomNumberGenerator.new()
        rock_rng.seed = rock_seed
        var rock_color_index = rock_rng.randi() % ProceduralModels.ROCK_COLORS.size()
        rock_instance.set_meta("rock_color_index", rock_color_index)
        
        add_child(rock_instance)
        placed_objects.append(rock_instance)
        
        # Spawn crystals on this rock with a chance (higher chance in hidden spots)
        _place_crystals_on_rock(rock_instance, rng, height)

## Place crystals on a rock
func _place_crystals_on_rock(rock_instance: MeshInstance3D, rng: RandomNumberGenerator, rock_height: float) -> void:
    # Get average chunk height to determine if rock is in a hidden/lower location
    var avg_height = 0.0
    var sample_count = 0
    for z in range(0, RESOLUTION, 4):
        for x in range(0, RESOLUTION, 4):
            avg_height += heightmap[z * (RESOLUTION + 1) + x]
            sample_count += 1
    avg_height /= sample_count
    
    # Increase spawn chance for rocks in lower/hidden locations
    var spawn_chance = CRYSTAL_SPAWN_CHANCE
    if rock_height < avg_height - 2.0:  # Rock is in a valley or lower area
        spawn_chance *= 1.8  # 80% increase in spawn chance for hidden spots
    elif rock_height < avg_height:  # Slightly below average
        spawn_chance *= 1.3  # 30% increase
    
    # Check if this rock should have crystals
    if rng.randf() > spawn_chance:
        return
    
    # Get rock color index for crystal type filtering
    var rock_color_index = rock_instance.get_meta("rock_color_index", 0)
    
    # Determine how many crystals to place
    var crystal_count = rng.randi_range(CRYSTALS_PER_ROCK_MIN, CRYSTALS_PER_ROCK_MAX)
    
    # Get rock position and size
    var rock_pos = rock_instance.position
    var rock_scale = rock_instance.scale.x if rock_instance.scale else 1.0
    
    for i in range(crystal_count):
        # Select random crystal type based on rock color
        var crystal_type = CrystalSystem.select_random_crystal_type(rng, rock_color_index)
        
        # Random size variation
        var size_scale = rng.randf_range(0.8, 1.5)
        
        # Position on rock surface (offset from center)
        var angle = rng.randf_range(0, TAU)
        var radius = rng.randf_range(0.3, 0.8) * rock_scale
        var offset_x = cos(angle) * radius
        var offset_z = sin(angle) * radius
        var offset_y = rng.randf_range(0.1, 0.4) * rock_scale  # Slightly above rock base
        
        # Create crystal instance
        var crystal_instance = MeshInstance3D.new()
        crystal_instance.mesh = CrystalSystem.create_crystal_mesh(crystal_type, size_scale, rng.randi())
        crystal_instance.material_override = CrystalSystem.create_crystal_material(crystal_type)
        crystal_instance.position = rock_pos + Vector3(offset_x, offset_y, offset_z)
        crystal_instance.rotation.y = rng.randf_range(0, TAU)
        # Slight tilt for natural look
        crystal_instance.rotation.x = rng.randf_range(-0.2, 0.2)
        crystal_instance.rotation.z = rng.randf_range(-0.2, 0.2)
        crystal_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        
        # Store crystal metadata for collection
        crystal_instance.set_meta("crystal_type", crystal_type)
        crystal_instance.set_meta("is_crystal", true)
        crystal_instance.set_meta("parent_rock", rock_instance)
        
        # Add to interactable group for click/tap detection
        crystal_instance.add_to_group("crystals")
        
        # Create collision area for interaction
        var area = Area3D.new()
        var collision_shape = CollisionShape3D.new()
        var shape = SphereShape3D.new()
        shape.radius = 0.3 * size_scale  # Slightly larger than visual for easier tapping
        collision_shape.shape = shape
        area.add_child(collision_shape)
        crystal_instance.add_child(area)
        
        # Store reference to the Area3D for signal connection
        crystal_instance.set_meta("interaction_area", area)
        
        add_child(crystal_instance)
        placed_crystals.append(crystal_instance)

## Place trees and buildings based on cluster system
func _place_cluster_objects() -> void:
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
func _place_forest_objects(cluster: ClusterSystem.ClusterData) -> void:
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
    # Increased multiplier from 0.02 to 0.05 for denser forests
    var tree_count = int(chunk_area * cluster.density * avg_influence * 0.05)
    
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
        
        # Create tree instance with automatic type variation
        var tree_instance = MeshInstance3D.new()
        tree_instance.mesh = ProceduralModels.create_tree_mesh(rng.randi(), ProceduralModels.TreeType.AUTO)
        tree_instance.material_override = ProceduralModels.create_tree_material()
        tree_instance.position = Vector3(local_x, height, local_z)
        tree_instance.rotation.y = rng.randf_range(0, TAU)  # Random rotation
        tree_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        
        add_child(tree_instance)
        placed_objects.append(tree_instance)

## Place buildings for a settlement cluster
func _place_settlement_objects(cluster: ClusterSystem.ClusterData) -> void:
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

## Generate and visualize paths in this chunk
func _generate_paths() -> void:
    # Get path segments for this chunk
    var chunk_pos = Vector2i(chunk_x, chunk_z)
    path_segments = PathSystem.get_path_segments_for_chunk(chunk_pos, seed_value)
    
    if path_segments.is_empty():
        return
    
    # Create path mesh
    _create_path_mesh()
    
    # Place bushes along path edges
    _place_path_bushes()

## Create visual mesh for paths
func _create_path_mesh() -> void:
    if path_segments.is_empty():
        return
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    for segment in path_segments:
        _add_path_segment_to_surface(surface_tool, segment)
    
    surface_tool.generate_normals()
    
    var path_mesh = surface_tool.commit()
    path_mesh_instance = MeshInstance3D.new()
    path_mesh_instance.mesh = path_mesh
    
    # Create path material - natural ground texture appearance
    var path_material = StandardMaterial3D.new()
    path_material.vertex_color_use_as_albedo = true
    path_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    path_material.roughness = 0.9  # Natural earth surface
    path_material.metallic = 0.0
    path_material.albedo_texture = null
    path_material.emission_enabled = false
    path_mesh_instance.set_surface_override_material(0, path_material)
    path_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # Ground texture, no distinct shadow
    
    add_child(path_mesh_instance)
    
    # Play endpoint sound if any segment is an endpoint
    for segment in path_segments:
        if segment.is_endpoint:
            _play_endpoint_sound(segment)

## Add a path segment to the surface tool
func _add_path_segment_to_surface(surface_tool: SurfaceTool, segment) -> void:
    var start = segment.start_pos
    var end = segment.end_pos
    var width = segment.width
    
    # Calculate perpendicular direction for width
    var direction = (end - start).normalized()
    var perpendicular = Vector2(-direction.y, direction.x)
    
    # Create 4 corners of the path segment
    var p1 = start + perpendicular * width / 2.0
    var p2 = start - perpendicular * width / 2.0
    var p3 = end + perpendicular * width / 2.0
    var p4 = end - perpendicular * width / 2.0
    
    # Get heights at corners - minimal elevation to prevent z-fighting
    var h1 = get_height_at_world_pos(chunk_x * CHUNK_SIZE + p1.x, chunk_z * CHUNK_SIZE + p1.y) + PATH_ELEVATION_OFFSET
    var h2 = get_height_at_world_pos(chunk_x * CHUNK_SIZE + p2.x, chunk_z * CHUNK_SIZE + p2.y) + PATH_ELEVATION_OFFSET
    var h3 = get_height_at_world_pos(chunk_x * CHUNK_SIZE + p3.x, chunk_z * CHUNK_SIZE + p3.y) + PATH_ELEVATION_OFFSET
    var h4 = get_height_at_world_pos(chunk_x * CHUNK_SIZE + p4.x, chunk_z * CHUNK_SIZE + p4.y) + PATH_ELEVATION_OFFSET
    
    # Calculate average height for terrain property variation
    var avg_height = (h1 + h2 + h3 + h4) / 4.0
    
    # Path color based on type and terrain properties
    var path_color = BRANCH_PATH_COLOR
    
    # Base color selection by path type
    if segment.path_type == PathSystem.PathType.MAIN_PATH:
        path_color = MAIN_PATH_COLOR
    elif segment.path_type == PathSystem.PathType.FOREST_PATH:
        # Forest paths are darker, more earthy
        path_color = Color(0.45, 0.42, 0.35)
    elif segment.path_type == PathSystem.PathType.VILLAGE_PATH:
        # Village paths are lighter, more worn
        path_color = Color(0.60, 0.55, 0.45)
    
    # Modify color based on biome/terrain height for variety
    if biome == "mountain":
        # Mountain paths are rocky, lighter gray-brown
        path_color = path_color.lerp(Color(0.55, 0.52, 0.48), 0.4)
    elif biome == "rocky_hills":
        # Rocky paths have more gray tones
        path_color = path_color.lerp(Color(0.50, 0.48, 0.44), 0.3)
    elif biome == "grassland":
        # Grassland paths are more brown/earthy
        path_color = path_color.lerp(Color(0.48, 0.44, 0.36), 0.2)
    
    # Endpoint paths are slightly brighter (well-traveled)
    if segment.is_endpoint:
        path_color = path_color.lerp(ENDPOINT_PATH_COLOR, 0.5)
    
    # Create two triangles for the path segment
    surface_tool.set_color(path_color)
    surface_tool.add_vertex(Vector3(p1.x, h1, p1.y))
    surface_tool.add_vertex(Vector3(p2.x, h2, p2.y))
    surface_tool.add_vertex(Vector3(p3.x, h3, p3.y))
    
    surface_tool.set_color(path_color)
    surface_tool.add_vertex(Vector3(p2.x, h2, p2.y))
    surface_tool.add_vertex(Vector3(p4.x, h4, p4.y))
    surface_tool.add_vertex(Vector3(p3.x, h3, p3.y))

## Play sound at path endpoint (placeholder)
func _play_endpoint_sound(segment) -> void:
    # TODO: Add actual sound file
    # For now, just print to console
    print("Path endpoint reached at chunk ", chunk_x, ", ", chunk_z, " - segment ", segment.segment_id)
    
    # Future: Load and play a special ambient sound
    # var audio_player = AudioStreamPlayer3D.new()
    # audio_player.stream = load("res://assets/sounds/path_endpoint.ogg")
    # audio_player.position = Vector3(segment.end_pos.x, get_height_at_world_pos(...), segment.end_pos.y)
    # add_child(audio_player)

## Place bushes along path edges for natural decoration
func _place_path_bushes() -> void:
    if path_segments.is_empty():
        return
    
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_value ^ hash(Vector2i(chunk_x, chunk_z)) ^ BUSH_SEED_OFFSET
    
    # Bush placement constants
    const BUSH_SPACING = 3.0  # Average distance between bushes
    const BUSH_OFFSET_FROM_EDGE = 1.2  # Distance from path edge
    const BUSH_PLACEMENT_CHANCE = 0.6  # 60% chance to place bush at each position
    const BUSH_SIZE_VARIATION = 0.3  # ±30% size variation
    
    for segment in path_segments:
        var start = segment.start_pos
        var end = segment.end_pos
        var width = segment.width
        
        # Calculate segment length
        var segment_length = start.distance_to(end)
        var direction = (end - start).normalized()
        var perpendicular = Vector2(-direction.y, direction.x)
        
        # Calculate number of bush positions along segment
        var num_positions = int(segment_length / BUSH_SPACING)
        
        for i in range(num_positions):
            # Position along the segment
            var t = float(i) / float(max(num_positions - 1, 1))
            var pos_along_path = start.lerp(end, t)
            
            # Try to place bushes on both sides of the path
            for side in [-1, 1]:
                if rng.randf() > BUSH_PLACEMENT_CHANCE:
                    continue
                
                # Position perpendicular to path edge
                var offset_distance = (width / 2.0) + BUSH_OFFSET_FROM_EDGE + rng.randf_range(-0.3, 0.3)
                var bush_pos_2d = pos_along_path + perpendicular * side * offset_distance
                
                # Check if position is within chunk bounds
                if bush_pos_2d.x < 0 or bush_pos_2d.x >= CHUNK_SIZE or bush_pos_2d.y < 0 or bush_pos_2d.y >= CHUNK_SIZE:
                    continue
                
                # Get terrain height
                var world_x = chunk_x * CHUNK_SIZE + bush_pos_2d.x
                var world_z = chunk_z * CHUNK_SIZE + bush_pos_2d.y
                var height = get_height_at_world_pos(world_x, world_z)
                
                # Skip if in lake
                if has_lake:
                    var dist_to_lake = Vector2(bush_pos_2d.x, bush_pos_2d.y).distance_to(lake_center)
                    if dist_to_lake < lake_radius:
                        continue
                
                # Create bush instance (using small bush tree type)
                var bush_instance = MeshInstance3D.new()
                bush_instance.mesh = ProceduralModels.create_tree_mesh(rng.randi(), ProceduralModels.TreeType.SMALL_BUSH)
                bush_instance.material_override = ProceduralModels.create_tree_material()
                bush_instance.position = Vector3(bush_pos_2d.x, height, bush_pos_2d.y)
                bush_instance.rotation.y = rng.randf_range(0, TAU)  # Random rotation
                
                # Size variation for natural look
                var size_scale = 1.0 + rng.randf_range(-BUSH_SIZE_VARIATION, BUSH_SIZE_VARIATION)
                bush_instance.scale = Vector3(size_scale, size_scale, size_scale)
                bush_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
                
                add_child(bush_instance)
                placed_objects.append(bush_instance)

## Generate ocean water for low-elevation chunks
func _generate_ocean_if_low() -> void:
    # Ocean chunks are identified during metadata calculation
    if not is_ocean:
        return
    
    # Create ocean water mesh covering the entire chunk
    _create_ocean_mesh()

## Create ocean water mesh covering the chunk
func _create_ocean_mesh() -> void:
    if not is_ocean:
        return
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Create a flat water plane at ocean level
    var ocean_color = Color(0.1, 0.3, 0.6, 0.7)  # Deep blue, semi-transparent
    
    # Define the four corners of the chunk
    var corners = [
        Vector3(0, ocean_water_level, 0),
        Vector3(CHUNK_SIZE, ocean_water_level, 0),
        Vector3(CHUNK_SIZE, ocean_water_level, CHUNK_SIZE),
        Vector3(0, ocean_water_level, CHUNK_SIZE)
    ]
    
    # Create two triangles to cover the chunk
    surface_tool.set_color(ocean_color)
    surface_tool.add_vertex(corners[0])
    surface_tool.add_vertex(corners[1])
    surface_tool.add_vertex(corners[2])
    
    surface_tool.set_color(ocean_color)
    surface_tool.add_vertex(corners[0])
    surface_tool.add_vertex(corners[2])
    surface_tool.add_vertex(corners[3])
    
    surface_tool.generate_normals()
    
    var ocean_mesh = surface_tool.commit()
    ocean_mesh_instance = MeshInstance3D.new()
    ocean_mesh_instance.mesh = ocean_mesh
    
    # Create ocean water material
    var water_material = StandardMaterial3D.new()
    water_material.vertex_color_use_as_albedo = true
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    water_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
    water_material.metallic = 0.0
    water_material.roughness = 0.05  # Smoother than lake water
    water_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
    
    ocean_mesh_instance.set_surface_override_material(0, water_material)
    add_child(ocean_mesh_instance)

## Place lighthouses along the coastline if this chunk borders ocean
func _place_lighthouses_if_coastal() -> void:
    # Only place lighthouses if this is NOT ocean but has ocean neighbors
    if is_ocean:
        return
    
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_value ^ hash(Vector2i(chunk_x, chunk_z)) ^ LIGHTHOUSE_SEED_OFFSET
    
    # Check if chunk position is on a regular grid for lighthouse placement
    # Place lighthouses every LIGHTHOUSE_SPACING units (approximately)
    var spacing_chunks = max(1, int(LIGHTHOUSE_SPACING / CHUNK_SIZE))  # Ensure at least 1
    
    # Only place lighthouse if this chunk is on the grid (either x or z coordinate matches)
    var on_x_grid = (chunk_x % spacing_chunks) == 0
    var on_z_grid = (chunk_z % spacing_chunks) == 0
    
    if not (on_x_grid or on_z_grid):
        return
    
    # Check if any neighboring chunks are ocean (coastal detection)
    var neighbors_to_check = [
        Vector2i(chunk_x - 1, chunk_z),  # West
        Vector2i(chunk_x + 1, chunk_z),  # East
        Vector2i(chunk_x, chunk_z - 1),  # North
        Vector2i(chunk_x, chunk_z + 1),  # South
    ]
    
    var has_ocean_neighbor = false
    for neighbor_pos in neighbors_to_check:
        # Simple heuristic: check if neighbor would be ocean based on noise
        var neighbor_height = _get_estimated_chunk_height(neighbor_pos)
        if neighbor_height <= OCEAN_LEVEL:
            has_ocean_neighbor = true
            break
    
    if not has_ocean_neighbor:
        return
    
    # Find suitable location for lighthouse near chunk edge facing ocean
    var lighthouse_pos = _find_coastal_position(rng)
    
    if lighthouse_pos:
        _place_lighthouse(lighthouse_pos, rng)

## Estimate average height of a chunk based on noise (without generating full chunk)
func _get_estimated_chunk_height(chunk_pos: Vector2i) -> float:
    # Sample a few points in the chunk to estimate average height
    var samples = 5
    var total_height = 0.0
    
    for i in range(samples):
        for j in range(samples):
            var world_x = chunk_pos.x * CHUNK_SIZE + (i * CHUNK_SIZE / samples)
            var world_z = chunk_pos.y * CHUNK_SIZE + (j * CHUNK_SIZE / samples)
            
            # Get biome value
            var biome_value = biome_noise.get_noise_2d(world_x, world_z)
            
            var height_multiplier = 10.0
            var height_offset = 0.0
            
            if biome_value > 0.3:
                height_multiplier = 20.0
                height_offset = 10.0
            elif biome_value < -0.2:
                height_multiplier = 5.0
                height_offset = -3.0
            
            var height = noise.get_noise_2d(world_x, world_z) * height_multiplier + height_offset
            total_height += height
    
    return total_height / (samples * samples)

## Find a suitable coastal position for lighthouse
func _find_coastal_position(rng: RandomNumberGenerator) -> Vector3:
    # Try to find a position near the edge of the chunk
    # Prefer elevated positions for better visibility
    
    var best_pos: Vector3 = Vector3.ZERO
    var best_height = -999999.0
    
    # Sample positions around the chunk perimeter
    var edge_samples = 8
    for i in range(edge_samples):
        var t = float(i) / float(edge_samples)
        var local_x = 0.0
        var local_z = 0.0
        
        # Sample all four edges
        var edge = i % 4
        match edge:
            0:  # North edge
                local_x = t * CHUNK_SIZE
                local_z = 2.0
            1:  # East edge
                local_x = CHUNK_SIZE - 2.0
                local_z = t * CHUNK_SIZE
            2:  # South edge
                local_x = t * CHUNK_SIZE
                local_z = CHUNK_SIZE - 2.0
            3:  # West edge
                local_x = 2.0
                local_z = t * CHUNK_SIZE
        
        var world_x = chunk_x * CHUNK_SIZE + local_x
        var world_z = chunk_z * CHUNK_SIZE + local_z
        var height = get_height_at_world_pos(world_x, world_z)
        
        # Check if this is walkable and elevated
        if height > best_height and height > OCEAN_LEVEL + 2.0:
            best_height = height
            best_pos = Vector3(local_x, height, local_z)
    
    # If no good position found, use chunk center
    if best_height == -999999.0:
        var center_x = CHUNK_SIZE / 2.0
        var center_z = CHUNK_SIZE / 2.0
        var world_x = chunk_x * CHUNK_SIZE + center_x
        var world_z = chunk_z * CHUNK_SIZE + center_z
        best_pos = Vector3(center_x, get_height_at_world_pos(world_x, world_z), center_z)
    
    return best_pos

## Place a lighthouse at the specified position
func _place_lighthouse(pos: Vector3, rng: RandomNumberGenerator) -> void:
    # Create lighthouse instance
    var lighthouse_instance = MeshInstance3D.new()
    lighthouse_instance.mesh = ProceduralModels.create_lighthouse_mesh(rng.randi())
    lighthouse_instance.material_override = ProceduralModels.create_lighthouse_material()
    lighthouse_instance.position = pos
    lighthouse_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    
    # Add light beacon on top
    var beacon_light = OmniLight3D.new()
    beacon_light.light_color = Color(1.0, 0.9, 0.6)  # Warm yellow light
    beacon_light.light_energy = 2.0
    beacon_light.omni_range = 30.0  # Wide range for visibility
    beacon_light.position = Vector3(0, ProceduralModels.LIGHTHOUSE_TOWER_HEIGHT + 2.0, 0)
    lighthouse_instance.add_child(beacon_light)
    
    add_child(lighthouse_instance)
    placed_lighthouses.append(lighthouse_instance)

## Setup wind ambient sound for mountain/high elevation regions
func _setup_wind_sound() -> void:
    # Only add wind sound to mountain biomes or high elevation areas
    if biome != "mountain":
        return
    
    # Calculate average height of the chunk
    var avg_height = 0.0
    for h in heightmap:
        avg_height += h
    avg_height /= heightmap.size()
    
    # Only add wind sound if average height is above 10 units (high mountains)
    if avg_height < 10.0:
        return
    
    # Create 3D audio player for spatial wind sound
    wind_sound_player = AudioStreamPlayer3D.new()
    wind_sound_player.max_distance = 50.0  # Audible from 50 units away
    wind_sound_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    wind_sound_player.unit_size = 10.0  # Sound source size
    
    # Position at chunk center, elevated
    var center_x = CHUNK_SIZE / 2.0
    var center_z = CHUNK_SIZE / 2.0
    var center_height = get_height_at_world_pos(chunk_x * CHUNK_SIZE + center_x, chunk_z * CHUNK_SIZE + center_z)
    wind_sound_player.position = Vector3(center_x, center_height + 5.0, center_z)
    
    # Create procedural wind sound using AudioStreamGenerator
    var generator = AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = 2.0  # 2 second buffer for looping
    
    wind_sound_player.stream = generator
    wind_sound_player.volume_db = -15.0  # Quieter ambient sound
    
    add_child(wind_sound_player)
    
    # Generate wind sound buffer once and let it loop
    call_deferred("_generate_wind_sound_buffer")

## Generate procedural wind whistling sound buffer (one-time generation)
func _generate_wind_sound_buffer() -> void:
    if not wind_sound_player:
        return
    
    # Start playing to initialize the stream
    wind_sound_player.play()
    
    # Wait for stream to initialize
    await get_tree().process_frame
    
    var playback = wind_sound_player.get_stream_playback() as AudioStreamGeneratorPlayback
    if not playback:
        return
    
    var generator = wind_sound_player.stream as AudioStreamGenerator
    var duration = generator.buffer_length
    var total_frames = int(generator.mix_rate * duration)
    
    # Pre-generate noise values for natural variation
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_value ^ hash(Vector2i(chunk_x, chunk_z))
    
    # Generate a looping wind sound buffer
    for i in range(total_frames):
        var t = float(i) / generator.mix_rate
        
        # Low frequency rumble (wind base) - slow varying
        var rumble = sin(2.0 * PI * 30.0 * t) * 0.3
        
        # High frequency whistle (wind through gaps) - with slow frequency modulation
        var freq_mod = sin(2.0 * PI * 0.3 * t) * 100.0  # Vary frequency slowly
        var whistle = sin(2.0 * PI * (800.0 + freq_mod) * t) * 0.15
        
        # Add deterministic noise for natural wind texture
        var noise_val = sin(2.0 * PI * 50.0 * t + rng.randf() * TAU) * 0.2
        
        # Slow amplitude modulation for varying wind intensity
        var modulation = (sin(2.0 * PI * 0.4 * t) + 1.0) / 2.0
        var sample = (rumble + whistle + noise_val) * modulation * 0.5
        
        # Push stereo frame
        playback.push_frame(Vector2(sample, sample))
        
        # Yield periodically to avoid blocking
        if i % 1000 == 0:
            await get_tree().process_frame


