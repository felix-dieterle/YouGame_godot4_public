extends Control
class_name MobileControls

# Virtual joystick
var joystick_base: Control
var joystick_stick: Control
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_vector: Vector2 = Vector2.ZERO

# Camera toggle button
var camera_toggle_button: Button

# Configuration
const JOYSTICK_RADIUS: float = 80.0
const STICK_RADIUS: float = 30.0
const DEADZONE: float = 0.2
const BUTTON_SIZE: float = 60.0
@export var joystick_margin_x: float = 120.0
@export var joystick_margin_y: float = 120.0
@export var button_margin_x: float = 80.0

# Player reference for camera toggle
var player: Node = null

func _ready():
	# Find player reference
	player = get_parent().get_node_or_null("Player")
	
	# Create virtual joystick (bottom left)
	joystick_base = Control.new()
	joystick_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	joystick_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	add_child(joystick_base)
	
	# Create camera toggle button (bottom right)
	_create_camera_toggle_button()
	
	# Update position when viewport size changes
	_update_joystick_position()
	get_viewport().size_changed.connect(_update_joystick_position)
	
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

func _create_camera_toggle_button():
	camera_toggle_button = Button.new()
	camera_toggle_button.text = "👁"  # Eye emoji for camera view
	camera_toggle_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	camera_toggle_button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	camera_toggle_button.add_theme_font_size_override("font_size", 30)
	
	# Set focus mode to prevent focus issues on mobile
	camera_toggle_button.focus_mode = Control.FOCUS_NONE
	
	# Ensure button is above other UI elements and can receive touch events
	camera_toggle_button.z_index = 10
	camera_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Style the button - normal state
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.3, 0.3, 0.7)
	button_style.corner_radius_top_left = int(BUTTON_SIZE / 2)
	button_style.corner_radius_top_right = int(BUTTON_SIZE / 2)
	button_style.corner_radius_bottom_left = int(BUTTON_SIZE / 2)
	button_style.corner_radius_bottom_right = int(BUTTON_SIZE / 2)
	camera_toggle_button.add_theme_stylebox_override("normal", button_style)
	
	# Style the button - hover state (for desktop/mouse support)
	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.4, 0.4, 0.4, 0.8)
	button_style_hover.corner_radius_top_left = int(BUTTON_SIZE / 2)
	button_style_hover.corner_radius_top_right = int(BUTTON_SIZE / 2)
	button_style_hover.corner_radius_bottom_left = int(BUTTON_SIZE / 2)
	button_style_hover.corner_radius_bottom_right = int(BUTTON_SIZE / 2)
	camera_toggle_button.add_theme_stylebox_override("hover", button_style_hover)
	
	# Style the button - pressed state
	var button_style_pressed = StyleBoxFlat.new()
	button_style_pressed.bg_color = Color(0.5, 0.5, 0.5, 0.9)
	button_style_pressed.corner_radius_top_left = int(BUTTON_SIZE / 2)
	button_style_pressed.corner_radius_top_right = int(BUTTON_SIZE / 2)
	button_style_pressed.corner_radius_bottom_left = int(BUTTON_SIZE / 2)
	button_style_pressed.corner_radius_bottom_right = int(BUTTON_SIZE / 2)
	camera_toggle_button.add_theme_stylebox_override("pressed", button_style_pressed)
	
	# Connect button to toggle function
	camera_toggle_button.pressed.connect(_on_camera_toggle_pressed)
	
	# Ensure button is visible
	camera_toggle_button.visible = true
	
	add_child(camera_toggle_button)
	# Defer positioning to ensure viewport size is ready
	call_deferred("_update_button_position")

func _update_button_position():
	if not camera_toggle_button:
		return
	
	# Position button in bottom-right corner with margin
	# Align vertically with the joystick center
	var viewport_size = get_viewport().size
	var button_x = viewport_size.x - button_margin_x - BUTTON_SIZE
	var button_y = viewport_size.y - joystick_margin_y - (BUTTON_SIZE / 2)
	camera_toggle_button.position = Vector2(button_x, button_y)

func _on_camera_toggle_pressed():
	# Toggle camera view on player
	if player and player.has_method("_toggle_camera_view"):
		player._toggle_camera_view()
