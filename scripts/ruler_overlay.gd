extends Control
class_name RulerOverlay

# Ruler overlay - displays a horizontal line with markers every 50 pixels
# Starting from the right edge at mid-height to the left edge

var is_visible: bool = true  # Initially visible
const MARKER_SPACING: int = 50  # Markers every 50 pixels

func _ready():
	# Ensure the control covers the full viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse interactions
	z_index = 50  # Display above most UI elements but below pause menu

func _draw():
	if not is_visible:
		return
	
	var viewport_size = get_viewport_rect().size
	var mid_height = viewport_size.y / 2.0
	
	# Draw horizontal line from right to left at mid-height
	var line_color = Color(1.0, 1.0, 1.0, 0.7)  # Semi-transparent white
	draw_line(Vector2(viewport_size.x, mid_height), Vector2(0, mid_height), line_color, 2.0)
	
	# Draw markers every 50 pixels from right to left
	var marker_height = 10.0  # Height of the marker line
	for x in range(int(viewport_size.x), 0, -MARKER_SPACING):
		# Draw vertical marker line
		draw_line(
			Vector2(x, mid_height - marker_height),
			Vector2(x, mid_height + marker_height),
			line_color,
			2.0
		)

func toggle_visibility():
	is_visible = not is_visible
	queue_redraw()  # Request redraw in Godot 4

func set_visible_state(visible: bool):
	is_visible = visible
	queue_redraw()

func get_visible_state() -> bool:
	return is_visible
