extends Control
class_name UIManager

# UI elements
var status_label: Label
var chunk_info_label: Label
var version_label: Label

# State
var initial_loading_complete: bool = false
var chunks_loaded: int = 0

# Timers for managing async operations
var status_timer: Timer
var chunk_timer: Timer

# Version label positioning constants
const VERSION_LABEL_OFFSET_LEFT: float = -200.0
const VERSION_LABEL_OFFSET_TOP: float = -30.0
const VERSION_LABEL_OFFSET_RIGHT: float = -10.0
const VERSION_LABEL_OFFSET_BOTTOM: float = -10.0

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
    
    # Create version label (bottom right)
    version_label = Label.new()
    version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    version_label.anchor_left = 1.0
    version_label.anchor_top = 1.0
    version_label.anchor_right = 1.0
    version_label.anchor_bottom = 1.0
    version_label.offset_left = VERSION_LABEL_OFFSET_LEFT
    version_label.offset_top = VERSION_LABEL_OFFSET_TOP
    version_label.offset_right = VERSION_LABEL_OFFSET_RIGHT
    version_label.offset_bottom = VERSION_LABEL_OFFSET_BOTTOM
    version_label.add_theme_font_size_override("font_size", 16)
    version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
    var version = ProjectSettings.get_setting("application/config/version", "1.0.0")
    version_label.text = "v" + version
    add_child(version_label)
    
    # Create timers
    status_timer = Timer.new()
    status_timer.one_shot = true
    status_timer.timeout.connect(_on_status_timer_timeout)
    add_child(status_timer)
    
    chunk_timer = Timer.new()
    chunk_timer.one_shot = true
    chunk_timer.timeout.connect(_on_chunk_timer_timeout)
    add_child(chunk_timer)
    
    # Show initial loading message
    show_message("Loading terrain...", 0)

func show_message(message: String, duration: float = 3.0):
    status_label.text = message
    status_label.visible = true
    
    # Stop any existing timer
    if status_timer.time_left > 0:
        status_timer.stop()
    
    if duration > 0:
        status_timer.start(duration)

func _on_status_timer_timeout():
    status_label.visible = false

func on_chunk_generated(chunk_pos: Vector2i):
    chunks_loaded += 1
    chunk_info_label.text = "Chunk generated: (%d, %d)" % [chunk_pos.x, chunk_pos.y]
    chunk_info_label.visible = true
    
    # Stop any existing timer and start new one
    if chunk_timer.time_left > 0:
        chunk_timer.stop()
    chunk_timer.start(2.0)

func _on_chunk_timer_timeout():
    chunk_info_label.visible = false

func on_initial_loading_complete():
    if not initial_loading_complete:
        initial_loading_complete = true
        show_message("Loading complete! Ready to explore.", 4.0)
