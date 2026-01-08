extends Control
class_name MobileControls

# Virtual joystick
var joystick_base: Control
var joystick_stick: Control
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_vector: Vector2 = Vector2.ZERO

# Menu button and settings panel
var menu_button: Button
var settings_panel: Panel
var settings_visible: bool = false

# Configuration
const JOYSTICK_RADIUS: float = 80.0
const STICK_RADIUS: float = 30.0
const DEADZONE: float = 0.2
const BUTTON_SIZE: float = 60.0
const PANEL_WIDTH: float = 300.0
const PANEL_HEIGHT: float = 350.0
@export var joystick_margin_x: float = 120.0
@export var joystick_margin_y: float = 120.0
@export var button_margin_x: float = 80.0

# Player reference for camera toggle
var player: Node = null

func _ready():
	DebugLogOverlay.add_log("MobileControls._ready() started", "yellow")
	
	# Find player reference
	player = get_parent().get_node_or_null("Player")
	DebugLogOverlay.add_log("Player reference: " + ("Found" if player else "NOT FOUND"), "yellow")
	
	# Create virtual joystick (bottom left)
	joystick_base = Control.new()
	joystick_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	joystick_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	add_child(joystick_base)
	DebugLogOverlay.add_log("Joystick base created", "green")
	
	# Create joystick visuals
	# Base circle
	var base_panel = Panel.new()
	base_panel.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	base_panel.position = Vector2(-JOYSTICK_RADIUS, -JOYSTICK_RADIUS)
	base_panel.modulate = Color(0.3, 0.3, 0.3, 0.5)
	joystick_base.add_child(base_panel)
	
	# Add StyleBox for circular appearance
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	base_style.corner_radius_top_left = int(JOYSTICK_RADIUS)
	base_style.corner_radius_top_right = int(JOYSTICK_RADIUS)
	base_style.corner_radius_bottom_left = int(JOYSTICK_RADIUS)
	base_style.corner_radius_bottom_right = int(JOYSTICK_RADIUS)
	base_panel.add_theme_stylebox_override("panel", base_style)
	
	# Stick circle
	joystick_stick = Control.new()
	joystick_stick.position = Vector2(0, 0)
	joystick_stick.size = Vector2(STICK_RADIUS * 2, STICK_RADIUS * 2)
	joystick_stick.pivot_offset = Vector2(STICK_RADIUS, STICK_RADIUS)
	joystick_base.add_child(joystick_stick)
	
	var stick_panel = Panel.new()
	stick_panel.size = Vector2(STICK_RADIUS * 2, STICK_RADIUS * 2)
	stick_panel.position = Vector2(-STICK_RADIUS, -STICK_RADIUS)
	stick_panel.modulate = Color(0.7, 0.7, 0.7, 0.7)
	joystick_stick.add_child(stick_panel)
	
	var stick_style = StyleBoxFlat.new()
	stick_style.bg_color = Color(0.7, 0.7, 0.7, 0.7)
	stick_style.corner_radius_top_left = int(STICK_RADIUS)
	stick_style.corner_radius_top_right = int(STICK_RADIUS)
	stick_style.corner_radius_bottom_left = int(STICK_RADIUS)
	stick_style.corner_radius_bottom_right = int(STICK_RADIUS)
	stick_panel.add_theme_stylebox_override("panel", stick_style)
	
	DebugLogOverlay.add_log("Joystick visuals created", "green")
	
	# Create menu button (bottom right)
	_create_menu_button()
	
	# Create settings panel (initially hidden)
	_create_settings_panel()
	
	# Update position when viewport size changes
	_update_joystick_position()
	get_viewport().size_changed.connect(_update_joystick_position)
	
	# Log MobileControls position and size info
	_log_control_info()
	
	DebugLogOverlay.add_log("MobileControls._ready() completed", "green")

func _update_joystick_position():
	# Position joystick in bottom-left corner with margin
	var viewport_size = get_viewport().size
	joystick_base.position = Vector2(joystick_margin_x, viewport_size.y - joystick_margin_y)
	_update_button_position()

func _input(event: InputEvent):
	# Handle touch input for virtual joystick
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		var touch_pos = touch.position
		var joystick_center = joystick_base.position
		var dist = touch_pos.distance_to(joystick_center)
		
		if touch.pressed and dist < JOYSTICK_RADIUS * 1.5:
			# Start joystick
			joystick_active = true
			joystick_touch_index = touch.index
			_update_joystick(touch_pos)
		elif not touch.pressed and touch.index == joystick_touch_index:
			# Release joystick
			joystick_active = false
			joystick_touch_index = -1
			joystick_vector = Vector2.ZERO
			joystick_stick.position = Vector2.ZERO
	
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		if joystick_active and drag.index == joystick_touch_index:
			_update_joystick(drag.position)

func _update_joystick(touch_pos: Vector2):
	var joystick_center = joystick_base.position
	var offset = touch_pos - joystick_center
	
	# Limit offset to joystick radius
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	
	joystick_stick.position = offset
	
	# Calculate normalized vector
	var normalized = offset / JOYSTICK_RADIUS
	
	# Apply deadzone
	if normalized.length() < DEADZONE:
		joystick_vector = Vector2.ZERO
	else:
		joystick_vector = normalized

func get_input_vector() -> Vector2:
	return joystick_vector

func _create_styled_button_style(bg_color: Color, corner_radius: int) -> StyleBoxFlat:
	# Helper function to create a styled button with rounded corners
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style

func _create_menu_button():
	DebugLogOverlay.add_log("Creating menu button...", "cyan")
	
	menu_button = Button.new()
	menu_button.text = "☰"  # Hamburger menu icon
	menu_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	menu_button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	menu_button.add_theme_font_size_override("font_size", 40)
	
	# Set focus mode to prevent focus issues on mobile
	menu_button.focus_mode = Control.FOCUS_NONE
	
	# Ensure button is above other UI elements and can receive touch events
	menu_button.z_index = 10
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	DebugLogOverlay.add_log("Menu button configured: z_index=%d, size=%.0fx%.0f" % [menu_button.z_index, BUTTON_SIZE, BUTTON_SIZE], "cyan")
	
	# Style the button states
	menu_button.add_theme_stylebox_override("normal", _create_styled_button_style(Color(0.3, 0.3, 0.3, 0.7), int(BUTTON_SIZE / 2)))
	menu_button.add_theme_stylebox_override("hover", _create_styled_button_style(Color(0.4, 0.4, 0.4, 0.8), int(BUTTON_SIZE / 2)))
	menu_button.add_theme_stylebox_override("pressed", _create_styled_button_style(Color(0.5, 0.5, 0.5, 0.9), int(BUTTON_SIZE / 2)))
	
	# Connect button to menu toggle function
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Ensure button is visible
	menu_button.visible = true
	
	add_child(menu_button)
	DebugLogOverlay.add_log("Menu button added to scene tree, visible=%s" % str(menu_button.visible), "green")
	
	# Defer positioning to ensure viewport size is ready
	call_deferred("_update_button_position")

func _create_settings_panel():
	DebugLogOverlay.add_log("Creating settings panel...", "cyan")
	
	# Create a panel for the settings menu
	settings_panel = Panel.new()
	settings_panel.z_index = 20  # Above the menu button
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_panel.visible = false  # Initially hidden
	
	DebugLogOverlay.add_log("Settings panel configured: z_index=%d, visible=%s" % [settings_panel.z_index, str(settings_panel.visible)], "cyan")
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Add padding container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	settings_panel.add_child(margin)
	
	# Create a vertical box container for menu items
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Settings"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(title_label)
	
	# Add a separator
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 10)
	vbox.add_child(separator1)
	
	# Camera toggle button
	var camera_button = Button.new()
	camera_button.text = "👁 Toggle First Person View"
	camera_button.custom_minimum_size = Vector2(0, 50)
	camera_button.add_theme_font_size_override("font_size", 18)
	camera_button.focus_mode = Control.FOCUS_NONE
	
	# Style the camera button
	camera_button.add_theme_stylebox_override("normal", _create_styled_button_style(Color(0.3, 0.3, 0.3, 1.0), 5))
	camera_button.add_theme_stylebox_override("hover", _create_styled_button_style(Color(0.4, 0.4, 0.4, 1.0), 5))
	camera_button.add_theme_stylebox_override("pressed", _create_styled_button_style(Color(0.5, 0.5, 0.5, 1.0), 5))
	
	camera_button.pressed.connect(_on_camera_toggle_pressed)
	vbox.add_child(camera_button)
	
	# Add a separator
	var separator2 = HSeparator.new()
	separator2.add_theme_constant_override("separation", 10)
	vbox.add_child(separator2)
	
	# Actions section label
	var actions_label = Label.new()
	actions_label.text = "Actions"
	actions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_label.add_theme_font_size_override("font_size", 20)
	actions_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(actions_label)
	
	# Placeholder for future actions
	var placeholder_label = Label.new()
	placeholder_label.text = "(More actions coming soon)"
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_font_size_override("font_size", 14)
	placeholder_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	vbox.add_child(placeholder_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(0, 45)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.focus_mode = Control.FOCUS_NONE
	
	# Style the close button
	close_button.add_theme_stylebox_override("normal", _create_styled_button_style(Color(0.5, 0.2, 0.2, 1.0), 5))
	close_button.add_theme_stylebox_override("hover", _create_styled_button_style(Color(0.6, 0.3, 0.3, 1.0), 5))
	
	close_button.pressed.connect(_on_close_settings_pressed)
	vbox.add_child(close_button)
	
	add_child(settings_panel)
	DebugLogOverlay.add_log("Settings panel added to scene tree", "green")
	
	# Defer positioning to ensure viewport size is ready
	call_deferred("_update_settings_panel_position")

func _on_menu_button_pressed():
	DebugLogOverlay.add_log("Menu button pressed!", "yellow")
	
	# Toggle settings panel visibility
	settings_visible = not settings_visible
	settings_panel.visible = settings_visible
	
	DebugLogOverlay.add_log("Settings panel visibility toggled to: %s" % str(settings_visible), "yellow")
	
	if settings_visible:
		_update_settings_panel_position()

func _on_close_settings_pressed():
	DebugLogOverlay.add_log("Close settings button pressed", "yellow")
	
	# Hide settings panel
	settings_visible = false
	settings_panel.visible = false

func _on_camera_toggle_pressed():
	DebugLogOverlay.add_log("Camera toggle pressed", "yellow")
	
	# Toggle camera view on player and close menu
	if player and player.has_method("_toggle_camera_view"):
		player._toggle_camera_view()
		DebugLogOverlay.add_log("Camera view toggled", "green")
	else:
		DebugLogOverlay.add_log("Player not found or method missing!", "red")
	
	# Close the settings menu after action
	_on_close_settings_pressed()

func _update_button_position():
	if not menu_button:
		DebugLogOverlay.add_log("ERROR: menu_button is null in _update_button_position", "red")
		return
	
	# Position button in bottom-right corner with margin
	# Align vertically with the joystick center
	var viewport_size = get_viewport().size
	var button_x = viewport_size.x - button_margin_x - BUTTON_SIZE
	var button_y = viewport_size.y - joystick_margin_y - (BUTTON_SIZE / 2)
	menu_button.position = Vector2(button_x, button_y)
	
	DebugLogOverlay.add_log("Menu button positioned at (%.0f, %.0f), viewport: %.0fx%.0f" % [button_x, button_y, viewport_size.x, viewport_size.y], "cyan")
	
	# Log absolute position after positioning
	if menu_button.is_inside_tree():
		var global_pos = menu_button.global_position
		DebugLogOverlay.add_log("Menu button global_position: (%.0f, %.0f)" % [global_pos.x, global_pos.y], "cyan")
		
		# Check if button top-left is within viewport (button may extend beyond)
		# Note: Y position uses (BUTTON_SIZE/2) offset to align with joystick center,
		# so button may intentionally extend beyond viewport bottom edge
		var top_left_in_bounds = (global_pos.x >= 0 and global_pos.y >= 0 and 
		                          global_pos.x < viewport_size.x and 
		                          global_pos.y < viewport_size.y)
		var fully_in_bounds = (global_pos.x >= 0 and global_pos.y >= 0 and 
		                       global_pos.x + BUTTON_SIZE <= viewport_size.x and 
		                       global_pos.y + BUTTON_SIZE <= viewport_size.y)
		
		DebugLogOverlay.add_log("Button top-left in viewport: %s" % str(top_left_in_bounds), 
		                        "green" if top_left_in_bounds else "red")
		DebugLogOverlay.add_log("Button fully in viewport: %s (may extend beyond due to centering)" % str(fully_in_bounds), 
		                        "green" if fully_in_bounds else "yellow")

func _update_settings_panel_position():
	if not settings_panel:
		DebugLogOverlay.add_log("ERROR: settings_panel is null in _update_settings_panel_position", "red")
		return
	
	# Position panel above the menu button, centered and sized appropriately
	var viewport_size = get_viewport().size
	
	# Center the panel horizontally, position it in the bottom half of the screen
	var panel_x = (viewport_size.x - PANEL_WIDTH) / 2
	var panel_y = viewport_size.y - PANEL_HEIGHT - joystick_margin_y - BUTTON_SIZE - 20
	
	settings_panel.position = Vector2(panel_x, panel_y)
	settings_panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	
	DebugLogOverlay.add_log("Settings panel positioned at (%.0f, %.0f), size: %.0fx%.0f" % [panel_x, panel_y, PANEL_WIDTH, PANEL_HEIGHT], "cyan")

func _log_control_info():
	# Log comprehensive information about the MobileControls control itself
	var viewport_size = get_viewport().size
	
	DebugLogOverlay.add_log("=== MobileControls Control Info ===", "cyan")
	DebugLogOverlay.add_log("Control position: (%.0f, %.0f)" % [position.x, position.y], "cyan")
	DebugLogOverlay.add_log("Control size: %.0fx%.0f" % [size.x, size.y], "cyan")
	DebugLogOverlay.add_log("Control global_position: (%.0f, %.0f)" % [global_position.x, global_position.y], "cyan")
	DebugLogOverlay.add_log("Viewport size: %.0fx%.0f" % [viewport_size.x, viewport_size.y], "cyan")
	DebugLogOverlay.add_log("anchor_left: %.2f, anchor_right: %.2f" % [anchor_left, anchor_right], "cyan")
	DebugLogOverlay.add_log("anchor_top: %.2f, anchor_bottom: %.2f" % [anchor_top, anchor_bottom], "cyan")
	DebugLogOverlay.add_log("offset_left: %.0f, offset_right: %.0f" % [offset_left, offset_right], "cyan")
	DebugLogOverlay.add_log("offset_top: %.0f, offset_bottom: %.0f" % [offset_top, offset_bottom], "cyan")
	DebugLogOverlay.add_log("clip_contents: %s" % str(clip_contents), "cyan")
	DebugLogOverlay.add_log("mouse_filter: %d (0=STOP, 1=PASS, 2=IGNORE)" % mouse_filter, "cyan")
	
	if menu_button:
		DebugLogOverlay.add_log("=== Menu Button Info ===", "cyan")
		DebugLogOverlay.add_log("Button position: (%.0f, %.0f)" % [menu_button.position.x, menu_button.position.y], "cyan")
		DebugLogOverlay.add_log("Button global_position: (%.0f, %.0f)" % [menu_button.global_position.x, menu_button.global_position.y], "cyan")
		DebugLogOverlay.add_log("Button size: %.0fx%.0f" % [menu_button.size.x, menu_button.size.y], "cyan")
		DebugLogOverlay.add_log("Button visible: %s, z_index: %d" % [str(menu_button.visible), menu_button.z_index], "cyan")
		DebugLogOverlay.add_log("Button is_visible_in_tree: %s" % str(menu_button.is_visible_in_tree()), "cyan")
		DebugLogOverlay.add_log("Button modulate: %s" % str(menu_button.modulate), "cyan")
		DebugLogOverlay.add_log("Button self_modulate: %s" % str(menu_button.self_modulate), "cyan")
		
		# Calculate expected screen bounds
		var button_right = menu_button.global_position.x + menu_button.size.x
		var button_bottom = menu_button.global_position.y + menu_button.size.y
		DebugLogOverlay.add_log("Button bounds: (%.0f, %.0f) to (%.0f, %.0f)" % [
			menu_button.global_position.x, menu_button.global_position.y,
			button_right, button_bottom
		], "cyan")
		
		# Check visibility in viewport
		# Note: Button may extend beyond viewport due to vertical centering with joystick
		var top_left_visible = (menu_button.global_position.x >= 0 and 
		                        menu_button.global_position.y >= 0 and 
		                        menu_button.global_position.x < viewport_size.x and 
		                        menu_button.global_position.y < viewport_size.y)
		var fully_visible = (menu_button.global_position.x >= 0 and 
		                     menu_button.global_position.y >= 0 and 
		                     button_right <= viewport_size.x and 
		                     button_bottom <= viewport_size.y)
		
		DebugLogOverlay.add_log("Button top-left in viewport: %s" % str(top_left_visible), 
		                        "green" if top_left_visible else "red")
		DebugLogOverlay.add_log("Button fully in viewport: %s (may extend due to centering)" % str(fully_visible), 
		                        "green" if fully_visible else "yellow")
