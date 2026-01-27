extends Control
class_name DirectionArrows

## Direction Arrows Overlay
##
## Displays arrows around the player pointing to:
## - Nearest water/ocean
## - Nearest crystal
## - The unique mountain

# Preload dependencies
const CrystalSystem = preload("res://scripts/crystal_system.gd")
const Chunk = preload("res://scripts/chunk.gd")

# References
var player: Node3D = null
var world_manager: Node3D = null
var camera: Camera3D = null

# Cached camera vectors for performance (updated every UPDATE_INTERVAL)
var cached_cam_forward_h: Vector3 = Vector3.ZERO
var cached_cam_right_h: Vector3 = Vector3.ZERO

# Arrow settings
const ARROW_DISTANCE_FROM_CENTER: float = 150.0  # Distance from screen center in pixels (avoids minimap in top-right)
const ARROW_SIZE: float = 30.0  # Size of arrow triangle
const ARROW_LINE_WIDTH: float = 3.0  # Width of arrow line
const MIN_DISTANCE_TO_SHOW: float = 10.0  # Don't show arrows for targets closer than 10m
# Note: This value must match Chunk.mountain_center_chunk_x/z initialization value
const INVALID_CHUNK_COORDINATE: int = 999999  # Marker for uninitialized chunk coordinates

# Arrow colors
const WATER_ARROW_COLOR: Color = Color(0.2, 0.5, 1.0, 0.8)  # Blue for water
const CRYSTAL_ARROW_COLOR: Color = Color(0.8, 0.2, 0.8, 0.8)  # Purple/pink for crystals
const MOUNTAIN_ARROW_COLOR: Color = Color(0.6, 0.6, 0.6, 0.8)  # Gray for mountain

# Target positions
var nearest_water_pos: Vector3 = Vector3.ZERO
var nearest_crystal_pos: Vector3 = Vector3.ZERO
var mountain_pos: Vector3 = Vector3.ZERO

# Update frequency
var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 1.0  # Update every 1 second

# Visibility
var arrows_visible: bool = true

func _ready() -> void:
	# Set up the overlay
	z_index = 60  # Above most UI but below pause menu
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input
	
	# Make control fill the viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Find references
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		player = main.get_node_or_null("Player")
		world_manager = main.get_node_or_null("WorldManager")
		if player:
			camera = player.get_node_or_null("Camera3D")
	
	# Initialize mountain position
	_find_mountain_position()

func _process(delta: float) -> void:
	if not arrows_visible:
		return
	
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		_update_targets()
		# Also update camera vectors on the same interval
		if camera:
			_update_camera_vectors()
	
	queue_redraw()

func _draw() -> void:
	if not arrows_visible or not camera or not player:
		return
	
	var screen_center = get_viewport_rect().size / 2.0
	
	# Draw arrows for each target
	if nearest_water_pos != Vector3.ZERO:
		_draw_arrow_to_target(nearest_water_pos, WATER_ARROW_COLOR, screen_center, "Wasser")
	
	# Crystal arrows are disabled (removed per user request)
	# if nearest_crystal_pos != Vector3.ZERO:
	#     _draw_arrow_to_target(nearest_crystal_pos, CRYSTAL_ARROW_COLOR, screen_center, "Kristall")
	
	if mountain_pos != Vector3.ZERO:
		_draw_arrow_to_target(mountain_pos, MOUNTAIN_ARROW_COLOR, screen_center, "Berg")

func _draw_arrow_to_target(target_pos: Vector3, color: Color, screen_center: Vector2, label_text: String) -> void:
	# Get direction from player to target in world space
	var player_pos = player.global_position
	
	# Calculate distance to target
	var distance = player_pos.distance_to(target_pos)
	
	# Don't show arrow if player is very close to target
	if distance < MIN_DISTANCE_TO_SHOW:
		return
	
	var direction_3d = (target_pos - player_pos).normalized()
	
	# Project to screen space - we only care about horizontal direction
	# Use cached camera vectors
	var forward_component = direction_3d.dot(cached_cam_forward_h)
	var right_component = direction_3d.dot(cached_cam_right_h)
	
	# Convert to 2D screen direction
	var screen_direction = Vector2(right_component, -forward_component).normalized()
	
	# Calculate arrow position on circle around center
	var arrow_pos = screen_center + screen_direction * ARROW_DISTANCE_FROM_CENTER
	
	# Draw arrow pointing toward target
	_draw_triangle_arrow(arrow_pos, screen_direction, color)
	
	# Draw distance label
	var distance_text = "%dm" % int(distance)
	var label_pos = arrow_pos + screen_direction * (ARROW_SIZE + 10)
	_draw_label(label_pos, label_text, distance_text, color)

func _draw_triangle_arrow(pos: Vector2, direction: Vector2, color: Color) -> void:
	# Calculate arrow triangle points
	var angle = direction.angle()
	var perpendicular = direction.rotated(PI / 2)
	
	# Triangle pointing in direction
	var tip = pos + direction * ARROW_SIZE * 0.7
	var base1 = pos - direction * ARROW_SIZE * 0.3 + perpendicular * ARROW_SIZE * 0.5
	var base2 = pos - direction * ARROW_SIZE * 0.3 - perpendicular * ARROW_SIZE * 0.5
	
	# Draw filled triangle
	var points = PackedVector2Array([tip, base1, base2])
	draw_colored_polygon(points, color)
	
	# Draw outline
	draw_line(tip, base1, Color.WHITE, 2.0)
	draw_line(base1, base2, Color.WHITE, 2.0)
	draw_line(base2, tip, Color.WHITE, 2.0)

func _draw_label(pos: Vector2, label: String, distance: String, color: Color) -> void:
	# Get default font
	var font = ThemeDB.fallback_font
	var font_size = 16
	
	# Draw label text
	var text = label + "\n" + distance
	var text_lines = text.split("\n")
	
	var y_offset = 0
	for line in text_lines:
		var text_size = font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = pos - Vector2(text_size.x / 2, -y_offset)
		
		# Draw shadow for better visibility
		draw_string(font, text_pos + Vector2(1, 1), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
		# Draw text
		draw_string(font, text_pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		
		y_offset += text_size.y

func _update_camera_vectors() -> void:
	if not camera:
		return
	
	# Get camera's basis vectors
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	
	# Pre-compute normalized horizontal vectors
	cached_cam_forward_h = Vector3(cam_forward.x, 0, cam_forward.z).normalized()
	cached_cam_right_h = Vector3(cam_right.x, 0, cam_right.z).normalized()

func _update_targets() -> void:
	if not world_manager or not player:
		return
	
	var player_pos = player.global_position
	
	# Find nearest water
	_find_nearest_water()
	
	# Find nearest crystal
	_find_nearest_crystal()
	
	# Update mountain position if not yet found
	if mountain_pos == Vector3.ZERO:
		_find_mountain_position()

func _find_nearest_water() -> void:
	if not world_manager:
		return
	
	var player_pos = player.global_position
	var nearest_distance = INF
	nearest_water_pos = Vector3.ZERO
	
	# Check all loaded chunks for ocean chunks
	for chunk_coord in world_manager.chunks:
		var chunk = world_manager.chunks[chunk_coord]
		if chunk and chunk.is_ocean:
			# Get chunk center position
			var chunk_pos = Vector3(
				chunk_coord.x * Chunk.CHUNK_SIZE + Chunk.CHUNK_SIZE / 2.0,
				Chunk.OCEAN_LEVEL,
				chunk_coord.y * Chunk.CHUNK_SIZE + Chunk.CHUNK_SIZE / 2.0
			)
			
			var distance = player_pos.distance_to(chunk_pos)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_water_pos = chunk_pos

func _find_nearest_crystal() -> void:
	if not world_manager:
		return
	
	var player_pos = player.global_position
	var nearest_distance = INF
	nearest_crystal_pos = Vector3.ZERO
	
	# Check all loaded chunks for crystals
	for chunk_coord in world_manager.chunks:
		var chunk = world_manager.chunks[chunk_coord]
		if chunk and chunk.placed_crystals:
			for crystal in chunk.placed_crystals:
				if is_instance_valid(crystal):
					var crystal_pos = crystal.global_position
					var distance = player_pos.distance_to(crystal_pos)
					if distance < nearest_distance:
						nearest_distance = distance
						nearest_crystal_pos = crystal_pos

func _find_mountain_position() -> void:
	# Find the unique mountain chunk
	# The mountain center chunk is determined by a special hash calculation
	# We need to search for the chunk that matches the criteria
	
	# Use the static variables from Chunk class if they're set
	if Chunk.mountain_center_chunk_x != INVALID_CHUNK_COORDINATE and Chunk.mountain_center_chunk_z != INVALID_CHUNK_COORDINATE:
		mountain_pos = Vector3(
			Chunk.mountain_center_chunk_x * Chunk.CHUNK_SIZE + Chunk.CHUNK_SIZE / 2.0,
			Chunk.MOUNTAIN_HEIGHT_OFFSET,
			Chunk.mountain_center_chunk_z * Chunk.CHUNK_SIZE + Chunk.CHUNK_SIZE / 2.0
		)
	else:
		# If not set yet, we need to find it
		# This is done by the chunk generation system
		# For now, set to zero and it will be updated when the mountain chunk loads
		mountain_pos = Vector3.ZERO

func set_arrows_visible(visible: bool) -> void:
	arrows_visible = visible
	queue_redraw()

func toggle_arrows() -> void:
	set_arrows_visible(not arrows_visible)
