extends Node
class_name ClusterSystem

## Cluster System for Forests and Settlements
## 
## This system manages procedural generation of forests and settlements that:
## - Adapt to chunk-based terrain expansion
## - Grow naturally across chunk boundaries
## - Are performance-optimized for mobile devices
## - Use seed-based generation for consistency

# Cluster types
enum ClusterType {
    FOREST,
    SETTLEMENT
}

# Cluster data structure
class ClusterData:
    var cluster_id: int
    var center_chunk: Vector2i  # Chunk where cluster originates
    var center_pos: Vector2  # Position within center chunk (0-CHUNK_SIZE)
    var type: ClusterType
    var radius: float  # Cluster influence radius in world units
    var density: float  # 0.0 to 1.0
    var seed_value: int
    
    func _init(id: int, chunk: Vector2i, pos: Vector2, t: ClusterType, r: float, d: float, s: int):
        cluster_id = id
        center_chunk = chunk
        center_pos = pos
        type = t
        radius = r
        density = d
        seed_value = s

# Global cluster registry
static var all_clusters: Dictionary = {}  # Key: cluster_id, Value: ClusterData
static var next_cluster_id: int = 0

# Constants
const CHUNK_SIZE = 32  # Must match Chunk.CHUNK_SIZE
const FOREST_MIN_RADIUS = 15.0
const FOREST_MAX_RADIUS = 40.0
const SETTLEMENT_MIN_RADIUS = 12.0
const SETTLEMENT_MAX_RADIUS = 25.0

## Get or generate clusters for a specific chunk
static func get_clusters_for_chunk(chunk_pos: Vector2i, world_seed: int) -> Array[ClusterData]:
    var clusters_in_chunk: Array[ClusterData] = []
    
    # Check existing clusters that might affect this chunk
    for cluster_id in all_clusters:
        var cluster: ClusterData = all_clusters[cluster_id]
        if _chunk_in_cluster_range(chunk_pos, cluster):
            clusters_in_chunk.append(cluster)
    
    # Try to generate new cluster centers in this chunk
    var new_clusters = _generate_cluster_centers_for_chunk(chunk_pos, world_seed)
    for cluster in new_clusters:
        clusters_in_chunk.append(cluster)
    
    return clusters_in_chunk

## Check if a chunk is within a cluster's influence
static func _chunk_in_cluster_range(chunk_pos: Vector2i, cluster: ClusterData) -> bool:
    var chunk_world_pos = Vector2(chunk_pos.x * CHUNK_SIZE, chunk_pos.y * CHUNK_SIZE)
    var cluster_world_pos = Vector2(
        cluster.center_chunk.x * CHUNK_SIZE + cluster.center_pos.x,
        cluster.center_chunk.y * CHUNK_SIZE + cluster.center_pos.y
    )
    
    # Check if chunk bounds overlap with cluster radius
    var chunk_center = chunk_world_pos + Vector2(CHUNK_SIZE / 2.0, CHUNK_SIZE / 2.0)
    var distance = chunk_center.distance_to(cluster_world_pos)
    
    # Add chunk diagonal to account for corners
    var chunk_extent = CHUNK_SIZE * 1.414  # sqrt(2) for diagonal
    return distance < (cluster.radius + chunk_extent)

## Generate new cluster centers that originate in this chunk
static func _generate_cluster_centers_for_chunk(chunk_pos: Vector2i, world_seed: int) -> Array[ClusterData]:
    var new_clusters: Array[ClusterData] = []
    
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(chunk_pos) ^ world_seed
    
    # Check if this chunk should be a cluster center
    # Forest: 15% chance per chunk
    if rng.randf() < 0.15:
        var cluster = _create_forest_cluster(chunk_pos, world_seed, rng)
        if cluster:
            new_clusters.append(cluster)
    
    # Settlement: 5% chance per chunk (if no forest)
    elif rng.randf() < 0.05:
        var cluster = _create_settlement_cluster(chunk_pos, world_seed, rng)
        if cluster:
            new_clusters.append(cluster)
    
    return new_clusters

## Create a forest cluster
static func _create_forest_cluster(chunk_pos: Vector2i, world_seed: int, rng: RandomNumberGenerator) -> ClusterData:
    # Check if cluster already exists at this position
    var cluster_key = "%d_%d_forest" % [chunk_pos.x, chunk_pos.y]
    if all_clusters.has(cluster_key):
        return null
    
    var cluster_id = next_cluster_id
    next_cluster_id += 1
    
    var center_pos = Vector2(
        rng.randf_range(8.0, CHUNK_SIZE - 8.0),
        rng.randf_range(8.0, CHUNK_SIZE - 8.0)
    )
    
    var radius = rng.randf_range(FOREST_MIN_RADIUS, FOREST_MAX_RADIUS)
    var density = rng.randf_range(0.3, 0.7)  # Trees per square unit
    
    var cluster = ClusterData.new(
        cluster_id,
        chunk_pos,
        center_pos,
        ClusterType.FOREST,
        radius,
        density,
        world_seed ^ cluster_id
    )
    
    all_clusters[cluster_key] = cluster
    return cluster

## Create a settlement cluster
static func _create_settlement_cluster(chunk_pos: Vector2i, world_seed: int, rng: RandomNumberGenerator) -> ClusterData:
    # Check if cluster already exists at this position
    var cluster_key = "%d_%d_settlement" % [chunk_pos.x, chunk_pos.y]
    if all_clusters.has(cluster_key):
        return null
    
    var cluster_id = next_cluster_id
    next_cluster_id += 1
    
    var center_pos = Vector2(
        rng.randf_range(8.0, CHUNK_SIZE - 8.0),
        rng.randf_range(8.0, CHUNK_SIZE - 8.0)
    )
    
    var radius = rng.randf_range(SETTLEMENT_MIN_RADIUS, SETTLEMENT_MAX_RADIUS)
    var density = rng.randf_range(0.15, 0.35)  # Buildings per square unit
    
    var cluster = ClusterData.new(
        cluster_id,
        chunk_pos,
        center_pos,
        ClusterType.SETTLEMENT,
        radius,
        density,
        world_seed ^ cluster_id
    )
    
    all_clusters[cluster_key] = cluster
    return cluster

## Get cluster influence at a specific world position
static func get_cluster_influence_at_pos(world_pos: Vector2, cluster: ClusterData) -> float:
    var cluster_world_pos = Vector2(
        cluster.center_chunk.x * CHUNK_SIZE + cluster.center_pos.x,
        cluster.center_chunk.y * CHUNK_SIZE + cluster.center_pos.y
    )
    
    var distance = world_pos.distance_to(cluster_world_pos)
    
    if distance > cluster.radius:
        return 0.0
    
    # Smooth falloff using cosine
    var normalized_dist = distance / cluster.radius
    return (cos(normalized_dist * PI) + 1.0) / 2.0

## Clear all clusters (for testing/reset)
static func clear_all_clusters():
    all_clusters.clear()
    next_cluster_id = 0
