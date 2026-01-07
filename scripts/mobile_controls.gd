extends Control
class_name MobileControls

# Virtual joystick
var joystick_base: Control
var joystick_stick: Control
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_vector: Vector2 = Vector2.ZERO

# Configuration
const JOYSTICK_RADIUS: float = 80.0
const STICK_RADIUS: float = 30.0
const DEADZONE: float = 0.2
@export var joystick_margin_x: float = 120.0
@export var joystick_margin_y: float = 120.0

func _ready():
	# Create virtual joystick (bottom left)
	joystick_base = Control.new()
	joystick_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	joystick_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	add_child(joystick_base)
	
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
