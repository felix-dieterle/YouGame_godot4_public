extends Control

# Debug Log Overlay - UI for displaying debug messages
# Used as an autoload singleton

# UI elements
var log_panel: Panel
var log_label: RichTextLabel
var toggle_button: Button
var clear_button: Button
var version_label: Label
var is_visible: bool = true  # Start visible to catch early logs

# Configuration
const PANEL_WIDTH: float = 600.0
const PANEL_HEIGHT: float = 400.0
const BUTTON_SIZE: float = 40.0
const MAX_LOG_LINES: int = 50

# Log storage
var log_messages: Array[String] = []

# Game version (cached)
var game_version: String = ""

# Singleton instance (type is inferred from autoload)
static var instance = null

func _ready():
    instance = self
    
    # Cache game version
    game_version = ProjectSettings.get_setting("application/config/version", "unknown")
    
    # Log how this instance is being loaded
    _log_instance_type()
    
    # Create toggle button (top left corner)
    _create_toggle_button()
    
    # Create clear button (next to toggle)
    _create_clear_button()
    
    # Create log panel
    _create_log_panel()
    
    # Create version label
    _create_version_label()
    
    # Update button position when viewport changes
    get_viewport().size_changed.connect(_update_button_positions)
    
    # Add initial log
    add_log("=== Debug Log System Started ===")
    add_log("Game Version: v" + game_version, "cyan")
    
    # Log which scene we are in
    _log_current_scene()

func _create_toggle_button():
    toggle_button = Button.new()
    toggle_button.text = "📋"  # Clipboard emoji for logs
    toggle_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    toggle_button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    toggle_button.add_theme_font_size_override("font_size", 20)
    toggle_button.focus_mode = Control.FOCUS_NONE
    toggle_button.z_index = 100  # Very high to be on top
    
    # Style the button
    var style_normal = StyleBoxFlat.new()
    style_normal.bg_color = Color(0.2, 0.4, 0.6, 0.8)
    style_normal.corner_radius_top_left = 5
    style_normal.corner_radius_top_right = 5
    style_normal.corner_radius_bottom_left = 5
    style_normal.corner_radius_bottom_right = 5
    toggle_button.add_theme_stylebox_override("normal", style_normal)
    
    var style_hover = StyleBoxFlat.new()
    style_hover.bg_color = Color(0.3, 0.5, 0.7, 0.9)
    style_hover.corner_radius_top_left = 5
    style_hover.corner_radius_top_right = 5
    style_hover.corner_radius_bottom_left = 5
    style_hover.corner_radius_bottom_right = 5
    toggle_button.add_theme_stylebox_override("hover", style_hover)
    
    toggle_button.pressed.connect(_on_toggle_pressed)
    add_child(toggle_button)
    _update_button_positions()

func _create_clear_button():
    clear_button = Button.new()
    clear_button.text = "🗑"  # Trash can emoji
    clear_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    clear_button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    clear_button.add_theme_font_size_override("font_size", 20)
    clear_button.focus_mode = Control.FOCUS_NONE
    clear_button.z_index = 100
    
    # Style the button
    var style_normal = StyleBoxFlat.new()
    style_normal.bg_color = Color(0.6, 0.2, 0.2, 0.8)
    style_normal.corner_radius_top_left = 5
    style_normal.corner_radius_top_right = 5
    style_normal.corner_radius_bottom_left = 5
    style_normal.corner_radius_bottom_right = 5
    clear_button.add_theme_stylebox_override("normal", style_normal)
    
    var style_hover = StyleBoxFlat.new()
    style_hover.bg_color = Color(0.7, 0.3, 0.3, 0.9)
    style_hover.corner_radius_top_left = 5
    style_hover.corner_radius_top_right = 5
    style_hover.corner_radius_bottom_left = 5
    style_hover.corner_radius_bottom_right = 5
    clear_button.add_theme_stylebox_override("hover", style_hover)
    
    clear_button.pressed.connect(_on_clear_pressed)
    add_child(clear_button)
    _update_button_positions()

func _update_button_positions():
    if toggle_button:
        toggle_button.position = Vector2(10, 10)
    if clear_button:
        clear_button.position = Vector2(10 + BUTTON_SIZE + 5, 10)

func _create_log_panel():
    # Create semi-transparent panel
    log_panel = Panel.new()
    log_panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
    log_panel.position = Vector2(10, 60)
    log_panel.visible = is_visible
    log_panel.z_index = 99  # Just below buttons
    
    # Style the panel - semi-transparent black with green border
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
    panel_style.border_width_left = 2
    panel_style.border_width_right = 2
    panel_style.border_width_top = 2
    panel_style.border_width_bottom = 2
    panel_style.border_color = Color(0.2, 0.8, 0.2, 1.0)
    panel_style.corner_radius_top_left = 8
    panel_style.corner_radius_top_right = 8
    panel_style.corner_radius_bottom_left = 8
    panel_style.corner_radius_bottom_right = 8
    log_panel.add_theme_stylebox_override("panel", panel_style)
    
    add_child(log_panel)
    
    # Create RichTextLabel for log text (supports colors and formatting)
    log_label = RichTextLabel.new()
    log_label.position = Vector2(10, 10)
    log_label.size = Vector2(PANEL_WIDTH - 20, PANEL_HEIGHT - 20)
    log_label.add_theme_font_size_override("normal_font_size", 12)
    log_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
    log_label.bbcode_enabled = true
    log_label.scroll_following = true  # Auto-scroll to bottom
    log_label.fit_content = false
    log_panel.add_child(log_label)

func _on_toggle_pressed():
    is_visible = not is_visible
    log_panel.visible = is_visible
    add_log("Debug log panel " + ("shown" if is_visible else "hidden"))

func _on_clear_pressed():
    log_messages.clear()
    _update_log_display()
    add_log("=== Log Cleared ===")

# Static method to add logs from anywhere
static func add_log(message: String, color: String = "white"):
    if instance:
        instance._add_log_internal(message, color)
    else:
        # Fallback to print if overlay not ready yet
        print("[DEBUG] " + message)

func _add_log_internal(message: String, color: String = "white"):
    var timestamp = Time.get_ticks_msec() / 1000.0
    var formatted_msg = "[color=%s][%.2fs] %s[/color]" % [color, timestamp, message]
    
    log_messages.append(formatted_msg)
    
    # Keep only the last MAX_LOG_LINES
    if log_messages.size() > MAX_LOG_LINES:
        log_messages = log_messages.slice(log_messages.size() - MAX_LOG_LINES, log_messages.size())
    
    _update_log_display()
    
    # Also print to console
    print("[DEBUG %.2fs] %s" % [timestamp, message])

func _update_log_display():
    if log_label:
        log_label.text = "\n".join(log_messages)

func _create_version_label():
    version_label = Label.new()
    version_label.text = "Version: v" + game_version
    version_label.add_theme_font_size_override("font_size", 14)
    version_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 0.9))
    version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    version_label.z_index = 100
    
    # Position in bottom-right corner
    version_label.anchor_left = 1.0
    version_label.anchor_top = 1.0
    version_label.anchor_right = 1.0
    version_label.anchor_bottom = 1.0
    version_label.offset_left = -150.0
    version_label.offset_top = -30.0
    version_label.offset_right = -10.0
    version_label.offset_bottom = -10.0
    version_label.visible = true  # Explicitly make visible
    
    add_child(version_label)

func _log_current_scene():
    # Get the current scene
    var current_scene = get_tree().current_scene
    
    if current_scene:
        var scene_name = current_scene.name
        var scene_path = current_scene.scene_file_path if current_scene.scene_file_path else "unknown"
        
        add_log("Current Scene: " + scene_name, "yellow")
        add_log("Scene Path: " + scene_path, "yellow")
        
        # Determine if we're in main or demo_narrative scene
        if scene_path.contains("main.tscn"):
            add_log("Scene Type: MAIN SCENE", "green")
        elif scene_path.contains("demo_narrative.tscn"):
            add_log("Scene Type: DEMO NARRATIVE SCENE", "green")
        else:
            add_log("Scene Type: UNKNOWN/OTHER SCENE", "orange")
    else:
        add_log("WARNING: Could not detect current scene!", "red")
        add_log("This may be because the scene is not fully loaded yet", "orange")
    
    # Also log version label visibility status
    if version_label:
        add_log("Version Label: visible=" + str(version_label.visible) + ", text='" + version_label.text + "'", "cyan")
        add_log("Version Label position: " + str(version_label.position) + ", z_index=" + str(version_label.z_index), "cyan")
    else:
        add_log("WARNING: Version label not created yet!", "red")

func _log_instance_type():
    # Check if we're running as an autoload or as a scene node
    var parent = get_parent()
    var is_autoload = parent == get_tree().root
    
    if is_autoload:
        print("[DEBUG] DebugLogOverlay: Running as AUTOLOAD SINGLETON")
    else:
        print("[DEBUG] DebugLogOverlay: Running as SCENE NODE (parent: " + str(parent.name if parent else "none") + ")")
        print("[DEBUG] WARNING: DebugLogOverlay should be an autoload, not a scene node!")
        print("[DEBUG] This duplicate instance may cause issues. Check main.tscn and remove the DebugLogOverlay node.")
