extends Control
class_name MinimapOverlay

## Minimap overlay that shows terrain, player position, and explored areas
## Positioned in the top-right corner with 20% transparency

# Configuration
const MAP_SIZE_RATIO: float = 0.2  # 1/5 of screen width
const MAP_OPACITY: float = 0.8  # 80% opacity (20% transparency)
const MAP_MARGIN: float = 10.0  # Margin from screen edges
const MAP_SCALE: float = 2.0  # How many world units per pixel
const VISITED_DECAY_TIME: float = 300.0  # 5 minutes before visited areas start to fade

# References
var world_manager = null
var player = null

# Map rendering
var map_texture: ImageTexture
var map_image: Image
var map_size: int = 200  # Will be calculated based on screen size

# Visited areas tracking (stores Vector2i chunk positions with timestamp)
var visited_chunks: Dictionary = {}

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
		map_texture = ImageTexture.create_from_image(map_image)
		map_rect.texture = map_texture

func _process(_delta: float) -> void:
	if not player or not world_manager:
		return
	
	# Update positioning if window size changed
	_update_positioning()
	
	# Track current chunk as visited
	var player_pos = player.global_position
	var chunk_x = int(floor(player_pos.x / world_manager.CHUNK_SIZE))
	var chunk_z = int(floor(player_pos.z / world_manager.CHUNK_SIZE))
	var chunk_pos = Vector2i(chunk_x, chunk_z)
	visited_chunks[chunk_pos] = Time.get_unix_time_from_system()
	
	# Update compass direction
	_update_compass()
	
	# Render the map
	_render_map()

func _update_compass() -> void:
	if not player:
		return
	
	# Get player's rotation and convert to compass direction
	var rotation_deg = rad_to_deg(player.rotation.y)
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
	
	# Render each pixel of the map
	for py in range(map_size):
		for px in range(map_size):
			# Convert pixel coordinates to world coordinates
			var world_x = min_x + (px / float(map_size)) * (max_x - min_x)
			var world_z = min_z + (py / float(map_size)) * (max_z - min_z)
			var world_pos = Vector3(world_x, 0, world_z)
			
			# Get terrain color at this position
			var color = _get_terrain_color(world_pos)
			
			# Check if this area has been visited (add slight highlight)
			var chunk_x = int(floor(world_x / world_manager.CHUNK_SIZE))
			var chunk_z = int(floor(world_z / world_manager.CHUNK_SIZE))
			var chunk_pos = Vector2i(chunk_x, chunk_z)
			
			if chunk_pos in visited_chunks:
				# Brighten visited areas slightly
				color = color.lightened(0.15)
			
			map_image.set_pixel(px, py, color)
	
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
	if water_depth > 0.1:
		var depth_factor = clamp(water_depth / 2.0, 0.0, 1.0)
		return Color(0.2 - depth_factor * 0.15, 0.4 - depth_factor * 0.2, 0.8 - depth_factor * 0.3, 1.0)
	
	# Land colors based on height
	# Low areas (green - grass/plains)
	if height < 2.0:
		return Color(0.3, 0.6, 0.3, 1.0)
	# Medium height (darker green - forests/hills)
	elif height < 5.0:
		return Color(0.2, 0.5, 0.2, 1.0)
	# High areas (brown/gray - mountains)
	elif height < 10.0:
		return Color(0.5, 0.4, 0.3, 1.0)
	# Very high (gray - peaks)
	else:
		return Color(0.6, 0.6, 0.6, 1.0)

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
	var rotation = player.rotation.y
	var arrow_length = 8
	var arrow_end_x = center_x + int(sin(rotation) * arrow_length)
	var arrow_end_y = center_y + int(cos(rotation) * arrow_length)
	
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
