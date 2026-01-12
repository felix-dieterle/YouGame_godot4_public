extends Node
class_name PathSystem

## Path System for procedural path/road generation
##
## This system generates paths that:
## - Start from the starting location
## - Continue across chunk boundaries
## - Branch randomly
## - Lead to forests and settlements
## - Can end with placeholder endpoints

# Preload dependencies
const ClusterSystem = preload("res://scripts/cluster_system.gd")

# Path types
enum PathType {
	MAIN_PATH,      # Main path from starting location
	BRANCH,         # Branch from main path
	FOREST_PATH,    # Path leading to forest
	VILLAGE_PATH    # Path leading to settlement
}

# Path segment data structure
class PathSegment:
	var segment_id: int
	var chunk_pos: Vector2i  # Chunk this segment is in
	var start_pos: Vector2   # Local position in chunk
	var end_pos: Vector2     # Local position in chunk
	var path_type: PathType
	var width: float         # Path width in world units
	var next_segments: Array[int] = []  # IDs of connected segments
	var is_endpoint: bool = false
	
	func _init(id: int, chunk: Vector2i, start: Vector2, end: Vector2, type: PathType, w: float):
		segment_id = id
		chunk_pos = chunk
		start_pos = start
		end_pos = end
		path_type = type
		width = w

# Global path registry
static var all_segments: Dictionary = {}  # Key: segment_id, Value: PathSegment
static var chunk_segments: Dictionary = {}  # Key: Vector2i chunk_pos, Value: Array[int] segment_ids
static var next_segment_id: int = 0

# Constants - Reference chunk size from a known constant
# Note: Must match the chunk size used in the game
const CHUNK_SIZE = 32.0  # Should match Chunk.CHUNK_SIZE
const DEFAULT_PATH_WIDTH = 1.5
const BRANCH_PROBABILITY = 0.15  # 15% chance to branch at each chunk
const ENDPOINT_PROBABILITY = 0.05  # 5% chance to end path
const MIN_SEGMENT_LENGTH = 8.0
const MAX_SEGMENT_LENGTH = 20.0
const PATH_ROUGHNESS = 0.3  # How much paths can deviate (0 = straight, 1 = very curvy)

## Generate or get path segments for a chunk
static func get_path_segments_for_chunk(chunk_pos: Vector2i, world_seed: int) -> Array[PathSegment]:
	# Check if we already have segments for this chunk
	if chunk_segments.has(chunk_pos):
		var segment_ids = chunk_segments[chunk_pos]
		var segments: Array[PathSegment] = []
		for id in segment_ids:
			if all_segments.has(id):
				segments.append(all_segments[id])
		return segments
	
	# Generate new segments
	return _generate_segments_for_chunk(chunk_pos, world_seed)

## Generate path segments for a chunk
static func _generate_segments_for_chunk(chunk_pos: Vector2i, world_seed: int) -> Array[PathSegment]:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_pos) ^ world_seed
	
	var new_segments: Array[PathSegment] = []
	
	# Check if this is the starting chunk (0, 0)
	if chunk_pos == Vector2i(0, 0):
		# Create initial main path from center going outward
		var center = Vector2(CHUNK_SIZE / 2.0, CHUNK_SIZE / 2.0)
		var direction = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var length = rng.randf_range(MIN_SEGMENT_LENGTH, MAX_SEGMENT_LENGTH)
		var end = center + direction * length
		
		# Clamp to chunk bounds or continue to next chunk
		var segment = _create_segment(chunk_pos, center, end, PathType.MAIN_PATH, rng)
		new_segments.append(segment)
	else:
		# Check for incoming paths from neighboring chunks
		new_segments = _continue_paths_from_neighbors(chunk_pos, world_seed, rng)
	
	# Register segments
	_register_segments(chunk_pos, new_segments)
	
	# Check if paths should branch or end
	for segment in new_segments:
		_try_create_branch(segment, world_seed, rng)
		_check_endpoint(segment, chunk_pos, world_seed, rng)
	
	return new_segments

## Continue paths from neighboring chunks
static func _continue_paths_from_neighbors(chunk_pos: Vector2i, world_seed: int, rng: RandomNumberGenerator) -> Array[PathSegment]:
	var continued_segments: Array[PathSegment] = []
	
	# Check all 4 neighboring chunks
	var neighbors = [
		Vector2i(chunk_pos.x - 1, chunk_pos.y),  # Left
		Vector2i(chunk_pos.x + 1, chunk_pos.y),  # Right
		Vector2i(chunk_pos.x, chunk_pos.y - 1),  # Top
		Vector2i(chunk_pos.x, chunk_pos.y + 1)   # Bottom
	]
	
	for neighbor_pos in neighbors:
		if not chunk_segments.has(neighbor_pos):
			continue
		
		var neighbor_segment_ids = chunk_segments[neighbor_pos]
		for seg_id in neighbor_segment_ids:
			if not all_segments.has(seg_id):
				continue
			
			var neighbor_segment: PathSegment = all_segments[seg_id]
			
			# Check if segment exits toward our chunk
			var exit_pos = _get_chunk_exit_position(neighbor_segment, neighbor_pos, chunk_pos)
			if exit_pos != Vector2(-1, -1):
				# Create continuation segment
				var entry_pos = _get_corresponding_entry_position(exit_pos, neighbor_pos, chunk_pos)
				var direction = (neighbor_segment.end_pos - neighbor_segment.start_pos).normalized()
				
				# Add some randomness to direction
				var angle_variation = rng.randf_range(-PI/6, PI/6) * PATH_ROUGHNESS
				direction = direction.rotated(angle_variation)
				
				var length = rng.randf_range(MIN_SEGMENT_LENGTH, MAX_SEGMENT_LENGTH)
				var end = entry_pos + direction * length
				
				var new_segment = _create_segment(chunk_pos, entry_pos, end, neighbor_segment.path_type, rng)
				continued_segments.append(new_segment)
	
	return continued_segments

## Get position where segment exits chunk (if any)
static func _get_chunk_exit_position(segment: PathSegment, segment_chunk: Vector2i, target_chunk: Vector2i) -> Vector2:
	var end = segment.end_pos
	var threshold = 2.0  # Distance from edge to consider exiting
	
	# Left neighbor
	if target_chunk.x < segment_chunk.x and end.x < threshold:
		return end
	# Right neighbor
	if target_chunk.x > segment_chunk.x and end.x > CHUNK_SIZE - threshold:
		return end
	# Top neighbor
	if target_chunk.y < segment_chunk.y and end.y < threshold:
		return end
	# Bottom neighbor
	if target_chunk.y > segment_chunk.y and end.y > CHUNK_SIZE - threshold:
		return end
	
	return Vector2(-1, -1)  # No exit

## Get entry position in new chunk corresponding to exit position from neighbor
static func _get_corresponding_entry_position(exit_pos: Vector2, from_chunk: Vector2i, to_chunk: Vector2i) -> Vector2:
	var entry = exit_pos
	
	# Left to right
	if to_chunk.x > from_chunk.x:
		entry.x = 0
	# Right to left
	elif to_chunk.x < from_chunk.x:
		entry.x = CHUNK_SIZE
	# Top to bottom
	if to_chunk.y > from_chunk.y:
		entry.y = 0
	# Bottom to top
	elif to_chunk.y < from_chunk.y:
		entry.y = CHUNK_SIZE
	
	return entry

## Create a path segment
static func _create_segment(chunk_pos: Vector2i, start: Vector2, end: Vector2, type: PathType, rng: RandomNumberGenerator) -> PathSegment:
	var segment_id = next_segment_id
	next_segment_id += 1
	
	# Clamp end position to reasonable bounds (can slightly exceed chunk for continuity)
	end.x = clamp(end.x, -2.0, CHUNK_SIZE + 2.0)
	end.y = clamp(end.y, -2.0, CHUNK_SIZE + 2.0)
	
	var width = DEFAULT_PATH_WIDTH
	if type == PathType.MAIN_PATH:
		width = DEFAULT_PATH_WIDTH * 1.2
	elif type == PathType.BRANCH:
		width = DEFAULT_PATH_WIDTH * 0.8
	
	var segment = PathSegment.new(segment_id, chunk_pos, start, end, type, width)
	all_segments[segment_id] = segment
	
	return segment

## Register segments for a chunk
static func _register_segments(chunk_pos: Vector2i, segments: Array[PathSegment]):
	if not chunk_segments.has(chunk_pos):
		chunk_segments[chunk_pos] = []
	
	for segment in segments:
		chunk_segments[chunk_pos].append(segment.segment_id)

## Try to create a branch from a segment
static func _try_create_branch(segment: PathSegment, world_seed: int, rng: RandomNumberGenerator):
	if segment.is_endpoint:
		return
	
	# Only branch from main paths
	if segment.path_type != PathType.MAIN_PATH:
		return
	
	if rng.randf() < BRANCH_PROBABILITY:
		# Try to target a nearby cluster (forest or settlement)
		var branch_type = _determine_branch_target(segment, world_seed, rng)
		
		# Create a branch
		var branch_start = segment.start_pos.lerp(segment.end_pos, 0.5)  # Branch from middle
		var main_direction = (segment.end_pos - segment.start_pos).normalized()
		var perpendicular = Vector2(-main_direction.y, main_direction.x)
		
		# Branch goes perpendicular with some randomness
		var branch_direction = perpendicular
		if rng.randf() > 0.5:
			branch_direction = -perpendicular
		
		# If we have a cluster target, adjust direction toward it
		var target_cluster = _find_nearest_cluster(segment, world_seed, 50.0)
		if target_cluster:
			var segment_world_pos = Vector2(
				segment.chunk_pos.x * CHUNK_SIZE + branch_start.x,
				segment.chunk_pos.y * CHUNK_SIZE + branch_start.y
			)
			var cluster_world_pos = Vector2(
				target_cluster.center_chunk.x * CHUNK_SIZE + target_cluster.center_pos.x,
				target_cluster.center_chunk.y * CHUNK_SIZE + target_cluster.center_pos.y
			)
			var to_cluster = (cluster_world_pos - segment_world_pos).normalized()
			
			# Blend between perpendicular and toward cluster
			branch_direction = branch_direction.lerp(to_cluster, 0.6).normalized()
			
			# Set branch type based on cluster
			if target_cluster.type == 0:  # FOREST (enum value 0)
				branch_type = PathType.FOREST_PATH
			else:  # SETTLEMENT (enum value 1)
				branch_type = PathType.VILLAGE_PATH
		
		var angle_variation = rng.randf_range(-PI/4, PI/4)
		branch_direction = branch_direction.rotated(angle_variation)
		
		var length = rng.randf_range(MIN_SEGMENT_LENGTH * 0.7, MAX_SEGMENT_LENGTH * 0.7)
		var branch_end = branch_start + branch_direction * length
		
		var branch_segment = _create_segment(segment.chunk_pos, branch_start, branch_end, branch_type, rng)
		
		# Link segments
		segment.next_segments.append(branch_segment.segment_id)
		
		# Register branch
		if chunk_segments.has(segment.chunk_pos):
			chunk_segments[segment.chunk_pos].append(branch_segment.segment_id)

## Determine what type of branch to create
static func _determine_branch_target(segment: PathSegment, world_seed: int, rng: RandomNumberGenerator) -> PathType:
	# Random choice between forest and village path
	if rng.randf() > 0.5:
		return PathType.FOREST_PATH
	else:
		return PathType.VILLAGE_PATH

## Find nearest cluster to a segment
static func _find_nearest_cluster(segment: PathSegment, world_seed: int, max_distance: float):
	var segment_world_pos = Vector2(
		segment.chunk_pos.x * CHUNK_SIZE + segment.end_pos.x,
		segment.chunk_pos.y * CHUNK_SIZE + segment.end_pos.y
	)
	
	# Check surrounding chunks for clusters using preloaded ClusterSystem
	var nearest_cluster = null
	var nearest_distance = max_distance
	
	for x in range(-3, 4):
		for y in range(-3, 4):
			var check_chunk = Vector2i(segment.chunk_pos.x + x, segment.chunk_pos.y + y)
			var clusters = ClusterSystem.get_clusters_for_chunk(check_chunk, world_seed)
			
			for cluster in clusters:
				var cluster_world_pos = Vector2(
					cluster.center_chunk.x * CHUNK_SIZE + cluster.center_pos.x,
					cluster.center_chunk.y * CHUNK_SIZE + cluster.center_pos.y
				)
				
				var distance = segment_world_pos.distance_to(cluster_world_pos)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_cluster = cluster
	
	return nearest_cluster

## Check if segment should be an endpoint
static func _check_endpoint(segment: PathSegment, chunk_pos: Vector2i, world_seed: int, rng: RandomNumberGenerator):
	# Check if segment ends near a forest or settlement cluster
	var segment_world_end = _segment_end_world_pos(segment)
	
	# Check for nearby clusters (using ClusterSystem if available)
	var near_cluster = _is_near_cluster(segment_world_end, world_seed)
	
	if near_cluster:
		segment.is_endpoint = true
		return
	
	# Random chance to end
	if rng.randf() < ENDPOINT_PROBABILITY:
		segment.is_endpoint = true

## Get world position of segment end
static func _segment_end_world_pos(segment: PathSegment) -> Vector2:
	return Vector2(
		segment.chunk_pos.x * CHUNK_SIZE + segment.end_pos.x,
		segment.chunk_pos.y * CHUNK_SIZE + segment.end_pos.y
	)

## Check if position is near a forest or settlement cluster
static func _is_near_cluster(world_pos: Vector2, world_seed: int) -> bool:
	# Get chunk position
	var chunk_x = int(floor(world_pos.x / CHUNK_SIZE))
	var chunk_y = int(floor(world_pos.y / CHUNK_SIZE))
	var chunk_pos = Vector2i(chunk_x, chunk_y)
	
	# Check for clusters using preloaded ClusterSystem
	var clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)
	
	for cluster in clusters:
		var cluster_world_pos = Vector2(
			cluster.center_chunk.x * CHUNK_SIZE + cluster.center_pos.x,
			cluster.center_chunk.y * CHUNK_SIZE + cluster.center_pos.y
		)
		
		var distance = world_pos.distance_to(cluster_world_pos)
		if distance < cluster.radius:
			return true
	
	return false

## Clear all path data (for testing/reset)
static func clear_all_paths():
	all_segments.clear()
	chunk_segments.clear()
	next_segment_id = 0

## Get total number of path segments
static func get_total_segments() -> int:
	return all_segments.size()
