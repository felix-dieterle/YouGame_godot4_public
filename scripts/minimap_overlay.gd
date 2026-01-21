extends Control
class_name MinimapOverlay

## Minimap overlay that shows terrain, player position, and explored areas
## Positioned in the top-right corner with 20% transparency

# Configuration
const MAP_SIZE_RATIO: float = 0.15  # Reduced from 0.2 for better performance (smaller map)
const MAP_OPACITY: float = 0.8  # 80% opacity (20% transparency)
const MAP_MARGIN: float = 10.0  # Margin from screen edges
const MAP_SCALE: float = 4.0  # Increased from 2.0 - wider area coverage with less detail
const UPDATE_INTERVAL: float = 0.2  # Increased from 0.1s - update every 0.2 seconds (5 FPS) for better performance
const POSITION_UPDATE_THRESHOLD: float = 5.0  # Increased from 2.0 - only update if player moved significantly
const PIXEL_SAMPLE_RATE: int = 2  # Only sample every Nth pixel for terrain (1=all pixels, 2=every other pixel, 3=every third)

# Terrain color thresholds and colors
const WATER_DEPTH_SHALLOW: float = 0.1
const WATER_DEPTH_SCALE: float = 2.0
const WATER_DARKNESS_R: float = 0.15
const WATER_DARKNESS_G: float = 0.2
const WATER_DARKNESS_B: float = 0.3

const HEIGHT_THRESHOLD_LOW: float = 2.0  # Plains/grass
const HEIGHT_THRESHOLD_MEDIUM: float = 5.0  # Forests/hills
const HEIGHT_THRESHOLD_HIGH: float = 10.0  # Mountains

const COLOR_WATER_BASE: Color = Color(0.2, 0.4, 0.8, 1.0)
const COLOR_PLAINS: Color = Color(0.3, 0.6, 0.3, 1.0)
const COLOR_FOREST: Color = Color(0.2, 0.5, 0.2, 1.0)
const COLOR_MOUNTAIN: Color = Color(0.5, 0.4, 0.3, 1.0)
const COLOR_PEAK: Color = Color(0.6, 0.6, 0.6, 1.0)

# References
var world_manager = null
var player = null

# Map rendering
var map_texture: ImageTexture
var map_image: Image
var map_size: int = 200  # Will be calculated based on screen size

# Visited areas tracking (stores Vector2i chunk positions)
var visited_chunks: Dictionary = {}

# Performance optimization
var update_timer: float = 0.0
var last_player_position: Vector3 = Vector3.ZERO
var last_player_chunk: Vector2i = Vector2i(-999999, -999999)  # Track last chunk to avoid redundant updates

# UI elements
var map_panel: PanelContainer
var map_rect: TextureRect
var compass_label: Label

func _ready() -> void:
	# Set up panel container for the minimap
	map_panel = PanelContainer.new()
	add_child(map_panel)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, MAP_OPACITY)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_color = Color(0.4, 0.4, 0.5, MAP_OPACITY)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	map_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create texture rect for rendering the map
	map_rect = TextureRect.new()
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	map_panel.add_child(map_rect)
	
	# Create compass label (centered at bottom of map)
	compass_label = Label.new()
	compass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass_label.add_theme_font_size_override("font_size", 16)
	compass_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, MAP_OPACITY))
	compass_label.text = "N"
	add_child(compass_label)
	
	# Position will be updated in _process when screen size is known
	_update_positioning()
	
	# Find references
	call_deferred("_find_references")

func _find_references() -> void:
	world_manager = get_tree().get_first_node_in_group("WorldManager")
	player = get_tree().get_first_node_in_group("Player")

func _update_positioning() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	map_size = int(viewport_size.x * MAP_SIZE_RATIO)
	
	# Position in top-right corner
	map_panel.position = Vector2(
		viewport_size.x - map_size - MAP_MARGIN,
		MAP_MARGIN
	)
	map_panel.size = Vector2(map_size, map_size)
	
	# Position compass below the map
	compass_label.position = Vector2(
		viewport_size.x - map_size - MAP_MARGIN,
		MAP_MARGIN + map_size + 5
	)
	compass_label.size = Vector2(map_size, 30)
	
	# Initialize or resize the map image
	if not map_image or map_image.get_width() != map_size:
		map_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
		if map_texture:
			map_texture.set_image(map_image)
		else:
			map_texture = ImageTexture.create_from_image(map_image)
		map_rect.texture = map_texture

func _process(delta: float) -> void:
	if not player or not world_manager:
		return
	
	# Update positioning if window size changed (infrequent check)
	if update_timer <= 0.0:
		_update_positioning()
	
	# Track current chunk and surrounding chunks as visited (5-chunk radius for 25x larger reveal area)
	var player_pos = player.global_position
	var chunk_x = int(floor(player_pos.x / world_manager.CHUNK_SIZE))
	var chunk_z = int(floor(player_pos.z / world_manager.CHUNK_SIZE))
	var current_chunk = Vector2i(chunk_x, chunk_z)
	
	# Only update visited chunks if player moved to a new chunk (performance optimization)
	if current_chunk != last_player_chunk:
		last_player_chunk = current_chunk
		
		# Mark all chunks within a 5-chunk radius as visited
		# This increases the reveal area 25x (area = π×r², so π×5² vs π×1²)
		var reveal_radius = 5
		var radius_squared = reveal_radius * reveal_radius
		for dx in range(-reveal_radius, reveal_radius + 1):
			for dz in range(-reveal_radius, reveal_radius + 1):
				# Only mark chunks within circular radius (not square)
				if dx * dx + dz * dz <= radius_squared:
					var chunk_pos = Vector2i(chunk_x + dx, chunk_z + dz)
					visited_chunks[chunk_pos] = true
	
	# Update compass direction (cheap operation)
	_update_compass()
	
	# Throttle expensive map rendering
	update_timer -= delta
	if update_timer <= 0.0:
		# Check if player moved significantly
		var distance_moved = player_pos.distance_to(last_player_position)
		if distance_moved > POSITION_UPDATE_THRESHOLD or last_player_position == Vector3.ZERO:
			_render_map()
			last_player_position = player_pos
		update_timer = UPDATE_INTERVAL

func _update_compass() -> void:
	if not player:
		return
	
	# Get player's rotation and convert to compass direction
	# Add 180° offset to align with map orientation (north at top)
	var rotation_deg = rad_to_deg(player.rotation.y) + 180.0
	rotation_deg = fmod(rotation_deg + 360.0, 360.0)
	
	# Determine cardinal direction
	var direction = ""
	if rotation_deg < 22.5 or rotation_deg >= 337.5:
		direction = "N"
	elif rotation_deg < 67.5:
		direction = "NE"
	elif rotation_deg < 112.5:
		direction = "E"
	elif rotation_deg < 157.5:
		direction = "SE"
	elif rotation_deg < 202.5:
		direction = "S"
	elif rotation_deg < 247.5:
		direction = "SW"
	elif rotation_deg < 292.5:
		direction = "W"
	else:
		direction = "NW"
	
	compass_label.text = "⬆ " + direction

func _render_map() -> void:
	if not map_image or not player or not world_manager:
		return
	
	var player_pos = player.global_position
	
	# Clear the image
	map_image.fill(Color(0, 0, 0, 0))
	
	# Calculate world coordinates for the map area
	var half_world_width = (map_size / 2) * MAP_SCALE
	var min_x = player_pos.x - half_world_width
	var max_x = player_pos.x + half_world_width
	var min_z = player_pos.z - half_world_width
	var max_z = player_pos.z + half_world_width
	
	# Render each pixel of the map with sampling optimization
	# Only render visited chunks to save performance (fog of war approach)
	for py in range(0, map_size, PIXEL_SAMPLE_RATE):
		for px in range(0, map_size, PIXEL_SAMPLE_RATE):
			# Convert pixel coordinates to world coordinates
			var world_x = min_x + (px / float(map_size)) * (max_x - min_x)
			var world_z = min_z + (py / float(map_size)) * (max_z - min_z)
			var world_pos = Vector3(world_x, 0, world_z)
			
			# Check if this area has been visited first (performance optimization)
			var chunk_x = int(floor(world_x / world_manager.CHUNK_SIZE))
			var chunk_z = int(floor(world_z / world_manager.CHUNK_SIZE))
			var chunk_pos = Vector2i(chunk_x, chunk_z)
			
			# Only render visited chunks (fog of war)
			if chunk_pos in visited_chunks:
				# Get terrain color at this position (expensive operation)
				var color = _get_terrain_color(world_pos)
				# Brighten visited areas slightly
				color = color.lightened(0.15)
				
				# Fill the sampled pixel block for smoother appearance
				for dy in range(PIXEL_SAMPLE_RATE):
					for dx in range(PIXEL_SAMPLE_RATE):
						var set_px = px + dx
						var set_py = py + dy
						if set_px < map_size and set_py < map_size:
							map_image.set_pixel(set_px, set_py, color)
	
	# Draw player position and direction
	_draw_player_indicator()
	
	# Update the texture
	map_texture.update(map_image)

func _get_terrain_color(world_pos: Vector3) -> Color:
	if not world_manager:
		return Color(0.3, 0.3, 0.3, 1.0)
	
	# Get terrain information
	var height = world_manager.get_height_at_position(world_pos)
	var water_depth = world_manager.get_water_depth_at_position(world_pos)
	
	# Water (blue, darker for deeper water)
	if water_depth > WATER_DEPTH_SHALLOW:
		var depth_factor = clamp(water_depth / WATER_DEPTH_SCALE, 0.0, 1.0)
		return Color(
			COLOR_WATER_BASE.r - depth_factor * WATER_DARKNESS_R,
			COLOR_WATER_BASE.g - depth_factor * WATER_DARKNESS_G,
			COLOR_WATER_BASE.b - depth_factor * WATER_DARKNESS_B,
			1.0
		)
	
	# Land colors based on height
	if height < HEIGHT_THRESHOLD_LOW:
		return COLOR_PLAINS  # Low areas (green - grass/plains)
	elif height < HEIGHT_THRESHOLD_MEDIUM:
		return COLOR_FOREST  # Medium height (darker green - forests/hills)
	elif height < HEIGHT_THRESHOLD_HIGH:
		return COLOR_MOUNTAIN  # High areas (brown/gray - mountains)
	else:
		return COLOR_PEAK  # Very high (gray - peaks)

func _draw_player_indicator() -> void:
	if not player or not map_image:
		return
	
	# Player is always at center of map
	var center_x = map_size / 2
	var center_y = map_size / 2
	
	# Draw player as a bright dot
	var player_color = Color(1.0, 1.0, 0.0, 1.0)  # Yellow
	var indicator_size = 3
	
	for dy in range(-indicator_size, indicator_size + 1):
		for dx in range(-indicator_size, indicator_size + 1):
			var px = center_x + dx
			var py = center_y + dy
			
			if px >= 0 and px < map_size and py >= 0 and py < map_size:
				if dx * dx + dy * dy <= indicator_size * indicator_size:
					map_image.set_pixel(px, py, player_color)
	
	# Draw direction indicator (arrow pointing in facing direction)
	# Note: In Godot, rotation.y follows right-hand rule around Y-axis
	# When viewed from above (top-down), increasing rotation.y rotates clockwise
	# rotation.y = 0 means facing forward along model's default orientation
	var rotation = player.rotation.y
	var arrow_length = 8
	var arrow_end_x = center_x + int(sin(rotation) * arrow_length)
	var arrow_end_y = center_y - int(cos(rotation) * arrow_length)  # Negate Y to match top-down view
	
	# Draw line from player to arrow end
	_draw_line(center_x, center_y, arrow_end_x, arrow_end_y, Color(1.0, 0.0, 0.0, 1.0))

func _draw_line(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	# Simple Bresenham's line algorithm
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	
	var x = x0
	var y = y0
	
	while true:
		if x >= 0 and x < map_size and y >= 0 and y < map_size:
			map_image.set_pixel(x, y, color)
		
		if x == x1 and y == y1:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
