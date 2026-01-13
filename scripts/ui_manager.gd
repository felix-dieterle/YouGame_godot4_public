extends Control
class_name UIManager

# UI elements
var status_label: Label
var chunk_info_label: Label
var version_label: Label
var time_label: Label
var night_overlay: ColorRect
var night_label: Label
var countdown_timer: Timer

# State
var initial_loading_complete: bool = false
var chunks_loaded: int = 0
var night_lockout_end_time: float = 0.0
var current_game_time: float = 0.0
var day_cycle_duration: float = 1800.0  # 30 minutes in seconds

# Timers for managing async operations
var status_timer: Timer
var chunk_timer: Timer

# Version label positioning constants
const VERSION_LABEL_OFFSET_LEFT: float = -200.0
const VERSION_LABEL_OFFSET_TOP: float = -30.0
const VERSION_LABEL_OFFSET_RIGHT: float = -10.0
const VERSION_LABEL_OFFSET_BOTTOM: float = -10.0
const VERSION_LABEL_Z_INDEX: int = 50  # Above most UI elements but below debug overlay

# Night overlay constants
const NIGHT_OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.1, 0.9)  # Very dark blue
const NIGHT_OVERLAY_Z_INDEX: int = 200  # Above everything else

# Game version
var game_version: String = ""

func _ready():
    # Ensure UI manager can function during pause
    process_mode = Node.PROCESS_MODE_ALWAYS
    
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
    
    # Create time label (bottom right, above version)
    time_label = Label.new()
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    time_label.anchor_left = 1.0
    time_label.anchor_top = 1.0
    time_label.anchor_right = 1.0
    time_label.anchor_bottom = 1.0
    time_label.offset_left = VERSION_LABEL_OFFSET_LEFT
    time_label.offset_top = VERSION_LABEL_OFFSET_TOP - 25.0  # Above version label
    time_label.offset_right = VERSION_LABEL_OFFSET_RIGHT
    time_label.offset_bottom = VERSION_LABEL_OFFSET_BOTTOM - 25.0
    time_label.add_theme_font_size_override("font_size", 16)
    time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7, 0.9))
    time_label.z_index = VERSION_LABEL_Z_INDEX
    time_label.text = "00:00"
    time_label.visible = true
    add_child(time_label)
    
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
    night_overlay.color = NIGHT_OVERLAY_COLOR
    night_overlay.z_index = NIGHT_OVERLAY_Z_INDEX
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
    
    # Create and show start menu if save file exists
    _create_start_menu()
    
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
    
    # Handle potential system time manipulation
    if time_remaining < -3600:  # If more than 1 hour in the past, something is wrong
        night_label.text = "Waking up..."
    elif time_remaining <= 0:
        night_label.text = "Waking up..."
    else:
        var hours = int(time_remaining / 3600)
        var minutes = int((time_remaining - hours * 3600) / 60)
        var seconds = int(time_remaining - hours * 3600 - minutes * 60)
        
        night_label.text = "Sleeping...\n\nYou cannot play for:\n%02d:%02d:%02d" % [hours, minutes, seconds]

# Update the in-game time display.
func update_game_time(time_seconds: float, cycle_duration: float):
    current_game_time = time_seconds
    day_cycle_duration = cycle_duration
    
    # Only update if time_label exists (may not exist during script validation)
    if not time_label:
        return
    
    # Convert game time to hours and minutes (24-hour format)
    # Start at 6:00 AM (sunrise), cycle through 24 hours
    var time_ratio = time_seconds / cycle_duration
    var total_minutes = int(time_ratio * 24.0 * 60.0) + 360  # Start at 6:00 AM (360 minutes)
    var hours = int(total_minutes / 60) % 24
    var minutes = int(total_minutes) % 60
    
    time_label.text = "%02d:%02d" % [hours, minutes]

func _create_start_menu():
    # Only show start menu if a save file exists
    if not SaveGameManager.has_save_file():
        return
    
    # Create overlay
    var start_overlay = ColorRect.new()
    start_overlay.name = "StartMenu"
    start_overlay.anchor_right = 1.0
    start_overlay.anchor_bottom = 1.0
    start_overlay.color = Color(0.0, 0.0, 0.0, 0.85)
    start_overlay.z_index = 250  # Above everything
    add_child(start_overlay)
    
    # Create panel
    var panel = Panel.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.size = Vector2(500, 400)
    panel.position = Vector2(-250, -200)
    
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
    panel_style.corner_radius_top_left = 15
    panel_style.corner_radius_top_right = 15
    panel_style.corner_radius_bottom_left = 15
    panel_style.corner_radius_bottom_right = 15
    panel_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
    panel_style.border_width_left = 3
    panel_style.border_width_right = 3
    panel_style.border_width_top = 3
    panel_style.border_width_bottom = 3
    panel.add_theme_stylebox_override("panel", panel_style)
    start_overlay.add_child(panel)
    
    # Create vbox
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 20)
    panel.add_child(vbox)
    
    # Add margin
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 40)
    margin.add_theme_constant_override("margin_right", 40)
    margin.add_theme_constant_override("margin_top", 40)
    margin.add_theme_constant_override("margin_bottom", 40)
    vbox.add_child(margin)
    
    var inner_vbox = VBoxContainer.new()
    inner_vbox.add_theme_constant_override("separation", 25)
    margin.add_child(inner_vbox)
    
    # Title
    var title = Label.new()
    title.text = "YouGame"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 48)
    title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    inner_vbox.add_child(title)
    
    # Spacer
    var spacer1 = Control.new()
    spacer1.custom_minimum_size = Vector2(0, 20)
    inner_vbox.add_child(spacer1)
    
    # Continue button
    var continue_button = Button.new()
    continue_button.text = "Continue Game"
    continue_button.custom_minimum_size = Vector2(0, 70)
    continue_button.add_theme_font_size_override("font_size", 24)
    continue_button.focus_mode = Control.FOCUS_NONE
    continue_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.2, 0.5, 0.2, 1.0), 10))
    continue_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.3, 0.6, 0.3, 1.0), 10))
    continue_button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.4, 0.7, 0.4, 1.0), 10))
    continue_button.pressed.connect(func(): _on_continue_game(start_overlay))
    inner_vbox.add_child(continue_button)
    
    # New game button
    var new_game_button = Button.new()
    new_game_button.text = "New Game"
    new_game_button.custom_minimum_size = Vector2(0, 70)
    new_game_button.add_theme_font_size_override("font_size", 24)
    new_game_button.focus_mode = Control.FOCUS_NONE
    new_game_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.3, 0.3, 0.5, 1.0), 10))
    new_game_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.4, 0.4, 0.6, 1.0), 10))
    new_game_button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.5, 0.5, 0.7, 1.0), 10))
    new_game_button.pressed.connect(func(): _on_new_game(start_overlay))
    inner_vbox.add_child(new_game_button)
    
    # Spacer
    var spacer2 = Control.new()
    spacer2.custom_minimum_size = Vector2(0, 10)
    spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inner_vbox.add_child(spacer2)
    
    # Info label
    var info_label = Label.new()
    info_label.text = "A saved game was found"
    info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_label.add_theme_font_size_override("font_size", 16)
    info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
    inner_vbox.add_child(info_label)
    
    # Pause the game until user makes a choice
    get_tree().paused = true

func _create_button_style(bg_color: Color, corner_radius: int) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.corner_radius_top_left = corner_radius
    style.corner_radius_top_right = corner_radius
    style.corner_radius_bottom_left = corner_radius
    style.corner_radius_bottom_right = corner_radius
    return style

func _on_continue_game(overlay: ColorRect):
    # Load is already done by SaveGameManager in other scripts
    # Just hide the menu and resume
    overlay.queue_free()
    get_tree().paused = false
    show_message("Game loaded! Welcome back.", 3.0)

func _on_new_game(overlay: ColorRect):
    # Delete save file and start fresh
    SaveGameManager.delete_save()
    overlay.queue_free()
    get_tree().paused = false
    show_message("New game started! Welcome to YouGame.", 3.0)

