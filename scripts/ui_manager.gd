extends Control
class_name UIManager

# UI elements
var status_label: Label
var chunk_info_label: Label
var version_label: Label
var night_overlay: ColorRect
var night_label: Label
var countdown_timer: Timer

# State
var initial_loading_complete: bool = false
var chunks_loaded: int = 0
var night_lockout_end_time: float = 0.0

# Timers for managing async operations
var status_timer: Timer
var chunk_timer: Timer

# Version label positioning constants
const VERSION_LABEL_OFFSET_LEFT: float = -200.0
const VERSION_LABEL_OFFSET_TOP: float = -30.0
const VERSION_LABEL_OFFSET_RIGHT: float = -10.0
const VERSION_LABEL_OFFSET_BOTTOM: float = -10.0
const VERSION_LABEL_Z_INDEX: int = 50  # Above most UI elements but below debug overlay

# Game version
var game_version: String = ""

func _ready():
    # Get game version
    game_version = ProjectSettings.get_setting("application/config/version", "1.0.0")
    
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
    version_label.z_index = VERSION_LABEL_Z_INDEX
    version_label.text = "v" + game_version
    version_label.visible = true  # Explicitly make visible
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
    
    # Create night overlay (initially hidden)
    night_overlay = ColorRect.new()
    night_overlay.anchor_right = 1.0
    night_overlay.anchor_bottom = 1.0
    night_overlay.color = Color(0.0, 0.0, 0.1, 0.9)  # Very dark blue
    night_overlay.z_index = 200  # Above everything else
    night_overlay.visible = false
    add_child(night_overlay)
    
    # Create night label
    night_label = Label.new()
    night_label.anchor_left = 0.5
    night_label.anchor_top = 0.5
    night_label.anchor_right = 0.5
    night_label.anchor_bottom = 0.5
    night_label.offset_left = -300
    night_label.offset_top = -100
    night_label.offset_right = 300
    night_label.offset_bottom = 100
    night_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    night_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    night_label.add_theme_font_size_override("font_size", 36)
    night_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
    night_overlay.add_child(night_label)
    
    # Create countdown timer for night screen
    countdown_timer = Timer.new()
    countdown_timer.wait_time = 1.0
    countdown_timer.timeout.connect(_on_countdown_timer_timeout)
    add_child(countdown_timer)
    
    # Show initial loading message with version
    show_message("YouGame v" + game_version + " - Loading terrain...", 0)

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

func show_night_overlay(lockout_end_time: float):
    night_lockout_end_time = lockout_end_time
    night_overlay.visible = true
    _update_night_countdown()
    countdown_timer.start()

func hide_night_overlay():
    night_overlay.visible = false
    countdown_timer.stop()

func _on_countdown_timer_timeout():
    _update_night_countdown()

func _update_night_countdown():
    if not night_overlay.visible:
        return
    
    var current_time = Time.get_unix_time_from_system()
    var time_remaining = night_lockout_end_time - current_time
    
    if time_remaining <= 0:
        night_label.text = "Waking up..."
    else:
        var hours = int(time_remaining / 3600)
        var minutes = int((time_remaining - hours * 3600) / 60)
        var seconds = int(time_remaining - hours * 3600 - minutes * 60)
        
        night_label.text = "Sleeping...\n\nYou cannot play for:\n%02d:%02d:%02d" % [hours, minutes, seconds]
