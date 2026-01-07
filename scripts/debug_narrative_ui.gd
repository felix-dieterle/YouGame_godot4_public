extends Control
class_name DebugNarrativeUI

# UI elements
var debug_panel: Panel
var debug_label: Label
var toggle_button: Button
var is_visible: bool = false

# References
var player: Node = null
var world_manager: Node = null
var quest_hook_system: Node = null

# Configuration
const PANEL_WIDTH: float = 400.0
const PANEL_HEIGHT: float = 300.0
const BUTTON_SIZE: float = 50.0
const UPDATE_INTERVAL: float = 0.5
const NEARBY_CHUNK_RADIUS: int = 5  # Search radius in chunks for nearby markers

# Update timer
var update_timer: float = 0.0

func _ready():
	# Find references
	player = get_parent().get_node_or_null("Player")
	world_manager = get_tree().get_first_node_in_group("WorldManager")
	quest_hook_system = get_parent().get_node_or_null("QuestHookSystem")
	
	# Create toggle button (top right corner)
	_create_toggle_button()
	
	# Create debug panel (initially hidden)
	_create_debug_panel()
	
	# Update button position when viewport changes
	get_viewport().size_changed.connect(_update_toggle_button_position)

func _create_toggle_button():
	toggle_button = Button.new()
	toggle_button.text = "🐛"  # Bug emoji for debug
	toggle_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	toggle_button.add_theme_font_size_override("font_size", 25)
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	toggle_button.add_theme_stylebox_override("normal", button_style)
	
	var button_style_pressed = StyleBoxFlat.new()
	button_style_pressed.bg_color = Color(0.4, 0.6, 0.4, 0.9)
	button_style_pressed.corner_radius_top_left = 8
	button_style_pressed.corner_radius_top_right = 8
	button_style_pressed.corner_radius_bottom_left = 8
	button_style_pressed.corner_radius_bottom_right = 8
	toggle_button.add_theme_stylebox_override("pressed", button_style_pressed)
	
	# Connect button
	toggle_button.pressed.connect(_on_toggle_pressed)
	
	add_child(toggle_button)
	_update_toggle_button_position()

func _update_toggle_button_position():
	var viewport_size = get_viewport().size
	toggle_button.position = Vector2(viewport_size.x - BUTTON_SIZE - 20, 20)

func _create_debug_panel():
	# Create semi-transparent panel
	debug_panel = Panel.new()
	debug_panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	debug_panel.position = Vector2(20, 80)
	debug_panel.visible = false
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.6, 0.3, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	debug_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(debug_panel)
	
	# Create label for debug text
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.size = Vector2(PANEL_WIDTH - 20, PANEL_HEIGHT - 20)
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	debug_panel.add_child(debug_label)

func _on_toggle_pressed():
	is_visible = not is_visible
	debug_panel.visible = is_visible
	
	if is_visible:
		_update_debug_info()

func _process(delta):
	if is_visible:
		update_timer += delta
		if update_timer >= UPDATE_INTERVAL:
			update_timer = 0.0
			_update_debug_info()

func _update_debug_info():
	var debug_text = "=== DEBUG NARRATIVE INFO ===\n\n"
	
	# Player info
	if player:
		debug_text += "Player Position: (%.1f, %.1f, %.1f)\n" % [
			player.global_position.x,
			player.global_position.y,
			player.global_position.z
		]
		
		# Get current chunk and terrain info
		if world_manager:
			var chunk = world_manager.get_chunk_at_position(player.global_position)
			if chunk:
				debug_text += "Chunk: (%d, %d)\n" % [chunk.chunk_x, chunk.chunk_z]
				debug_text += "Biome: %s\n" % chunk.biome
				debug_text += "Landmark: %s\n" % (chunk.landmark_type if chunk.landmark_type else "none")
				
				var terrain_material = world_manager.get_terrain_material_at_position(player.global_position)
				debug_text += "Terrain Material: %s\n" % terrain_material
			
			debug_text += "\n"
	
	# Narrative markers nearby
	debug_text += "--- Nearby Markers ---\n"
	var nearby_markers = _get_nearby_markers(NEARBY_CHUNK_RADIUS)
	if nearby_markers.size() > 0:
		for i in range(min(5, nearby_markers.size())):
			var marker = nearby_markers[i]
			var dist = player.global_position.distance_to(marker.world_position) if player else 0.0
			debug_text += "• %s (%.1fm)\n" % [marker.marker_type, dist]
			debug_text += "  Importance: %.2f\n" % marker.importance
	else:
		debug_text += "No markers nearby\n"
	
	debug_text += "\n"
	
	# Quest system info
	if quest_hook_system:
		var total_markers = quest_hook_system.get_total_marker_count()
		debug_text += "--- Quest System ---\n"
		debug_text += "Total Markers: %d\n" % total_markers
	
	debug_label.text = debug_text

func _get_nearby_markers(chunk_radius: int = NEARBY_CHUNK_RADIUS) -> Array:
	var markers = []
	
	if not world_manager or not player:
		return markers
	
	var player_chunk = world_manager.get_chunk_at_position(player.global_position)
	if not player_chunk:
		return markers
	
	# Get markers from nearby chunks
	var center_x = player_chunk.chunk_x
	var center_z = player_chunk.chunk_z
	
	for dx in range(-chunk_radius, chunk_radius + 1):
		for dz in range(-chunk_radius, chunk_radius + 1):
			var chunk_pos = Vector2i(center_x + dx, center_z + dz)
			var chunk = world_manager.chunks.get(chunk_pos)
			if chunk:
				markers.append_array(chunk.get_narrative_markers())
	
	return markers
