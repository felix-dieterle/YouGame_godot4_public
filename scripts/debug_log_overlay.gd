extends Control
class_name DebugLogOverlay

# UI elements
var log_panel: Panel
var log_label: RichTextLabel
var toggle_button: Button
var clear_button: Button
var is_visible: bool = true  # Start visible to catch early logs

# Configuration
const PANEL_WIDTH: float = 600.0
const PANEL_HEIGHT: float = 400.0
const BUTTON_SIZE: float = 40.0
const MAX_LOG_LINES: int = 50

# Log storage
var log_messages: Array[String] = []

# Singleton instance
static var instance: DebugLogOverlay = null

func _ready():
	instance = self
	
	# Create toggle button (top left corner)
	_create_toggle_button()
	
	# Create clear button (next to toggle)
	_create_clear_button()
	
	# Create log panel
	_create_log_panel()
	
	# Update button position when viewport changes
	get_viewport().size_changed.connect(_update_button_positions)
	
	# Add initial log
	add_log("=== Debug Log System Started ===")

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
