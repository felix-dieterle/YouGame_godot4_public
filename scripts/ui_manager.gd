extends Control
class_name UIManager

# UI elements
var status_label: Label
var chunk_info_label: Label

# State
var initial_loading_complete: bool = false
var chunks_loaded: int = 0

func _ready():
	# Create status label (top center)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	status_label.position = Vector2(0, 20)
	status_label.size = Vector2(get_viewport().size.x, 50)
	status_label.add_theme_font_size_override("font_size", 24)
	add_child(status_label)
	
	# Create chunk info label (top left)
	chunk_info_label = Label.new()
	chunk_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	chunk_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	chunk_info_label.position = Vector2(20, 80)
	chunk_info_label.size = Vector2(400, 50)
	chunk_info_label.add_theme_font_size_override("font_size", 18)
	add_child(chunk_info_label)
	
	# Show initial loading message
	show_message("Loading terrain...", 0)

func show_message(message: String, duration: float = 3.0):
	status_label.text = message
	status_label.visible = true
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		status_label.visible = false

func on_chunk_generated(chunk_pos: Vector2i):
	chunks_loaded += 1
	chunk_info_label.text = "Chunk generated: (%d, %d)" % [chunk_pos.x, chunk_pos.y]
	chunk_info_label.visible = true
	
	# Hide chunk info after 2 seconds
	await get_tree().create_timer(2.0).timeout
	chunk_info_label.visible = false

func on_initial_loading_complete():
	if not initial_loading_complete:
		initial_loading_complete = true
		show_message("Loading complete! Ready to explore.", 4.0)
