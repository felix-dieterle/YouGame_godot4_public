extends Control
class_name MobileControls

# Virtual joystick (movement)
var joystick_base: Control
var joystick_stick: Control
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_vector: Vector2 = Vector2.ZERO

# Virtual joystick (camera/look)
var look_joystick_base: Control
var look_joystick_stick: Control
var look_joystick_active: bool = false
var look_joystick_touch_index: int = -1
var look_joystick_vector: Vector2 = Vector2.ZERO
var look_direction_indicator: Control  # Visual indicator for current look direction

# Menu button and settings panel
var menu_button: Button
var settings_panel: Panel
var settings_visible: bool = false

# Configuration
const JOYSTICK_RADIUS: float = 80.0
const STICK_RADIUS: float = 30.0
const DEADZONE: float = 0.2
const JOYSTICK_DETECTION_MULTIPLIER: float = 1.5  # Multiplier for joystick detection radius
const BUTTON_SIZE: float = 60.0
const PANEL_WIDTH: float = 300.0
const PANEL_HEIGHT: float = 350.0
const INDICATOR_MARGIN: float = 10.0  # Margin for direction indicator from edge
const INDICATOR_WIDTH: float = 6.0  # Width of direction indicator line
@export var joystick_margin_x: float = 120.0
@export var joystick_margin_y: float = 120.0
@export var look_joystick_margin_x: float = 120.0  # Right margin for look joystick
@export var look_joystick_margin_y: float = 120.0  # Bottom margin for look joystick
@export var button_margin_x: float = 80.0

# Player reference for camera toggle
var player: Node = null

# Pause menu reference (cached)
var pause_menu: Node = null

func _ready() -> void:
    DebugLogOverlay.add_log("MobileControls._ready() started", "yellow")
    
    # Ensure MobileControls can always process, even when game is paused
    # This allows the settings menu to work at all times
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Find player reference
    player = get_parent().get_node_or_null("Player")
    DebugLogOverlay.add_log("Player reference: " + ("Found" if player else "NOT FOUND"), "yellow")
    
    # Find pause menu reference
    pause_menu = get_tree().get_first_node_in_group("PauseMenu")
    DebugLogOverlay.add_log("Pause menu reference: " + ("Found" if pause_menu else "NOT FOUND"), "yellow")
    
    # Create virtual joystick (bottom left)
    joystick_base = Control.new()
    joystick_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
    joystick_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
    # Set z_index to ensure joystick renders above UI elements
    # With parent MobileControls z_index=10, need child z_index >= 91 for effective > 100
    # (UIManager elements like version_label have effective z_index of 100)
    joystick_base.z_index = 95
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
    
    # Create look joystick (bottom right)
    _create_look_joystick()
    
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

func _process(_delta: float) -> void:
    # Update the look direction indicator to show where the camera is pointing
    _update_look_direction_indicator()

func _update_look_direction_indicator() -> void:
    # Update the visual indicator to show current look direction
    if not player or not player.has("camera_rotation_x") or not player.has("camera_rotation_y"):
        return
    
    if not look_direction_indicator:
        return
    
    # Get camera rotation from player
    var yaw = player.camera_rotation_y    # Horizontal rotation (radians)
    
    # Set the rotation of the indicator to show yaw direction
    # The indicator points upward when yaw=0 (straight ahead)
    # and rotates left/right as the player looks left/right
    look_direction_indicator.rotation = yaw

func _update_joystick_position() -> void:
    # Position joystick in bottom-left corner with margin
    var viewport_size = get_viewport_rect().size
    # Account for joystick size so margin is from edge to edge, not edge to top-left corner
    # Position is top-left, so subtract the full diameter (JOYSTICK_RADIUS * 2) and add back margin
    joystick_base.position = Vector2(joystick_margin_x, viewport_size.y - joystick_margin_y - JOYSTICK_RADIUS * 2)
    
    # Position look joystick in bottom-right corner with margin
    # Add extra margin to keep it away from version/time labels
    # Account for joystick size so it stays within viewport bounds
    look_joystick_base.position = Vector2(viewport_size.x - look_joystick_margin_x - JOYSTICK_RADIUS * 2, viewport_size.y - look_joystick_margin_y - JOYSTICK_RADIUS * 2)
    
    DebugLogOverlay.add_log("Joystick positions updated:", "cyan")
    DebugLogOverlay.add_log("  Movement joystick: (%.0f, %.0f)" % [joystick_base.position.x, joystick_base.position.y], "cyan")
    DebugLogOverlay.add_log("  Look joystick: (%.0f, %.0f)" % [look_joystick_base.position.x, look_joystick_base.position.y], "cyan")
    DebugLogOverlay.add_log("  Viewport size: %.0fx%.0f" % [viewport_size.x, viewport_size.y], "cyan")
    
    _update_button_position()

func _input(event: InputEvent) -> void:
    # Handle touch input for virtual joysticks
    if event is InputEventScreenTouch:
        var touch = event as InputEventScreenTouch
        var touch_pos = touch.position
        var joystick_center = joystick_base.position
        var look_joystick_center = look_joystick_base.position
        var dist = touch_pos.distance_to(joystick_center)
        var look_dist = touch_pos.distance_to(look_joystick_center)
        
        if touch.pressed:
            # Check which joystick is closer and within range
            if dist < JOYSTICK_RADIUS * JOYSTICK_DETECTION_MULTIPLIER and (look_dist >= JOYSTICK_RADIUS * JOYSTICK_DETECTION_MULTIPLIER or dist < look_dist):
                # Start movement joystick
                joystick_active = true
                joystick_touch_index = touch.index
                _update_joystick(touch_pos)
            elif look_dist < JOYSTICK_RADIUS * JOYSTICK_DETECTION_MULTIPLIER:
                # Start look joystick
                look_joystick_active = true
                look_joystick_touch_index = touch.index
                _update_look_joystick(touch_pos)
        else:
            # Release joysticks
            if touch.index == joystick_touch_index:
                joystick_active = false
                joystick_touch_index = -1
                joystick_vector = Vector2.ZERO
                joystick_stick.position = Vector2.ZERO
            elif touch.index == look_joystick_touch_index:
                look_joystick_active = false
                look_joystick_touch_index = -1
                look_joystick_vector = Vector2.ZERO
                look_joystick_stick.position = Vector2.ZERO
    
    elif event is InputEventScreenDrag:
        var drag = event as InputEventScreenDrag
        if joystick_active and drag.index == joystick_touch_index:
            _update_joystick(drag.position)
        elif look_joystick_active and drag.index == look_joystick_touch_index:
            _update_look_joystick(drag.position)

func _update_joystick(touch_pos: Vector2) -> void:
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

func get_look_vector() -> Vector2:
    return look_joystick_vector

func _create_look_joystick() -> void:
    DebugLogOverlay.add_log("Creating look joystick...", "cyan")
    
    # Create look joystick base
    look_joystick_base = Control.new()
    look_joystick_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
    look_joystick_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
    # Set z_index to ensure joystick renders above UI elements
    # With parent MobileControls z_index=10, need child z_index >= 91 for effective > 100
    # (UIManager elements like version_label have effective z_index of 100)
    look_joystick_base.z_index = 95
    add_child(look_joystick_base)
    
    # Base circle
    var base_panel = Panel.new()
    base_panel.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
    base_panel.position = Vector2(-JOYSTICK_RADIUS, -JOYSTICK_RADIUS)
    base_panel.modulate = Color(0.6, 0.3, 0.3, 0.7)  # More visible reddish tint (increased opacity and red channel)
    look_joystick_base.add_child(base_panel)
    
    # Add StyleBox for circular appearance
    var base_style = StyleBoxFlat.new()
    base_style.bg_color = Color(0.6, 0.3, 0.3, 0.7)  # More visible reddish tint
    base_style.corner_radius_top_left = int(JOYSTICK_RADIUS)
    base_style.corner_radius_top_right = int(JOYSTICK_RADIUS)
    base_style.corner_radius_bottom_left = int(JOYSTICK_RADIUS)
    base_style.corner_radius_bottom_right = int(JOYSTICK_RADIUS)
    base_panel.add_theme_stylebox_override("panel", base_style)
    
    # Stick circle
    look_joystick_stick = Control.new()
    look_joystick_stick.position = Vector2(0, 0)
    look_joystick_stick.size = Vector2(STICK_RADIUS * 2, STICK_RADIUS * 2)
    look_joystick_stick.pivot_offset = Vector2(STICK_RADIUS, STICK_RADIUS)
    look_joystick_base.add_child(look_joystick_stick)
    
    var stick_panel = Panel.new()
    stick_panel.size = Vector2(STICK_RADIUS * 2, STICK_RADIUS * 2)
    stick_panel.position = Vector2(-STICK_RADIUS, -STICK_RADIUS)
    stick_panel.modulate = Color(0.9, 0.5, 0.5, 0.85)  # More visible reddish stick (increased opacity and brightness)
    look_joystick_stick.add_child(stick_panel)
    
    var stick_style = StyleBoxFlat.new()
    stick_style.bg_color = Color(0.9, 0.5, 0.5, 0.85)  # More visible reddish stick
    stick_style.corner_radius_top_left = int(STICK_RADIUS)
    stick_style.corner_radius_top_right = int(STICK_RADIUS)
    stick_style.corner_radius_bottom_left = int(STICK_RADIUS)
    stick_style.corner_radius_bottom_right = int(STICK_RADIUS)
    stick_panel.add_theme_stylebox_override("panel", stick_style)
    
    # Create direction indicator (shows current look direction relative to straight ahead)
    var indicator_length = JOYSTICK_RADIUS - INDICATOR_MARGIN
    look_direction_indicator = Control.new()
    look_direction_indicator.position = Vector2(0, 0)
    look_direction_indicator.size = Vector2(INDICATOR_WIDTH, indicator_length)  # Thin rectangle extending upward
    look_direction_indicator.pivot_offset = Vector2(INDICATOR_WIDTH / 2, 0)  # Pivot at the base (center of joystick)
    look_joystick_base.add_child(look_direction_indicator)
    
    var indicator_panel = Panel.new()
    indicator_panel.size = Vector2(INDICATOR_WIDTH, indicator_length)
    indicator_panel.position = Vector2(-INDICATOR_WIDTH / 2, -indicator_length)  # Position extending upward from pivot
    indicator_panel.modulate = Color(1.0, 1.0, 0.0, 0.9)  # Bright yellow for visibility
    look_direction_indicator.add_child(indicator_panel)
    
    var indicator_style = StyleBoxFlat.new()
    indicator_style.bg_color = Color(1.0, 1.0, 0.0, 0.9)  # Bright yellow
    indicator_style.corner_radius_top_left = 3
    indicator_style.corner_radius_top_right = 3
    indicator_style.corner_radius_bottom_left = 3
    indicator_style.corner_radius_bottom_right = 3
    indicator_panel.add_theme_stylebox_override("panel", indicator_style)
    
    DebugLogOverlay.add_log("Look joystick visuals created", "green")
    DebugLogOverlay.add_log("Look joystick base visible: %s" % str(look_joystick_base.visible), "cyan")
    DebugLogOverlay.add_log("Look joystick stick visible: %s" % str(look_joystick_stick.visible), "cyan")

func _update_look_joystick(touch_pos: Vector2) -> void:
    var joystick_center = look_joystick_base.position
    var offset = touch_pos - joystick_center
    
    # Limit offset to joystick radius
    if offset.length() > JOYSTICK_RADIUS:
        offset = offset.normalized() * JOYSTICK_RADIUS
    
    look_joystick_stick.position = offset
    
    # Calculate normalized vector
    var normalized = offset / JOYSTICK_RADIUS
    
    # Apply deadzone
    if normalized.length() < DEADZONE:
        look_joystick_vector = Vector2.ZERO
    else:
        look_joystick_vector = normalized

func _create_styled_button_style(bg_color: Color, corner_radius: int) -> StyleBoxFlat:
    # Helper function to create a styled button with rounded corners
    var style = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.corner_radius_top_left = corner_radius
    style.corner_radius_top_right = corner_radius
    style.corner_radius_bottom_left = corner_radius
    style.corner_radius_bottom_right = corner_radius
    return style

func _create_menu_button() -> void:
    DebugLogOverlay.add_log("Creating menu button...", "cyan")
    
    menu_button = Button.new()
    menu_button.text = "☰"  # Hamburger menu icon
    menu_button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    menu_button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    menu_button.add_theme_font_size_override("font_size", 40)
    
    # Set focus mode to prevent focus issues on mobile
    menu_button.focus_mode = Control.FOCUS_NONE
    
    # Ensure button is above other UI elements and can receive touch events
    # Set z-index high to ensure it renders above all other UI elements
    # With parent MobileControls z-index 10, effective z-index is 10+101=111
    # This places it above debug overlay (effective z-index 104-105)
    menu_button.z_index = 101
    menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
    # Ensure button can always process input, even if game is paused
    menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
    
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

func _create_settings_panel() -> void:
    DebugLogOverlay.add_log("Creating settings panel...", "cyan")
    
    # Create a panel for the settings menu
    settings_panel = Panel.new()
    # Set z-index high to ensure it renders above all other UI elements, including the menu button
    # With parent MobileControls z-index 10, effective z-index is 10+102=112
    # This places it above menu button (111) and debug overlay (104-105)
    settings_panel.z_index = 102
    settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    settings_panel.visible = false  # Initially hidden
    # Ensure settings panel can always process input, even if game is paused
    settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
    
    DebugLogOverlay.add_log("Settings panel configured: z_index=%d, visible=%s" % [settings_panel.z_index, str(settings_panel.visible)], "cyan")
    
    # Style the panel with improved colors
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
    panel_style.corner_radius_top_left = 12
    panel_style.corner_radius_top_right = 12
    panel_style.corner_radius_bottom_left = 12
    panel_style.corner_radius_bottom_right = 12
    panel_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
    panel_style.border_width_left = 3
    panel_style.border_width_right = 3
    panel_style.border_width_top = 3
    panel_style.border_width_bottom = 3
    settings_panel.add_theme_stylebox_override("panel", panel_style)
    
    # Add padding container
    var margin = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    settings_panel.add_child(margin)
    
    # Create a vertical box container for menu items
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 12)
    margin.add_child(vbox)
    
    # Title label
    var title_label = Label.new()
    title_label.text = "⚙ Settings"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 28)
    title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    vbox.add_child(title_label)
    
    # Add a separator
    var separator1 = HSeparator.new()
    separator1.add_theme_constant_override("separation", 12)
    vbox.add_child(separator1)
    
    # Display section
    var display_section = Label.new()
    display_section.text = "Display"
    display_section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    display_section.add_theme_font_size_override("font_size", 20)
    display_section.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
    vbox.add_child(display_section)
    
    # Camera toggle button
    var camera_button = Button.new()
    camera_button.text = "👁 Toggle First Person View"
    camera_button.custom_minimum_size = Vector2(0, 55)
    camera_button.add_theme_font_size_override("font_size", 18)
    camera_button.focus_mode = Control.FOCUS_NONE
    
    # Style the camera button
    camera_button.add_theme_stylebox_override("normal", _create_styled_button_style(Color(0.25, 0.35, 0.45, 1.0), 8))
    camera_button.add_theme_stylebox_override("hover", _create_styled_button_style(Color(0.35, 0.45, 0.55, 1.0), 8))
    camera_button.add_theme_stylebox_override("pressed", _create_styled_button_style(Color(0.45, 0.55, 0.65, 1.0), 8))
    
    camera_button.pressed.connect(_on_camera_toggle_pressed)
    vbox.add_child(camera_button)
    
    # Add a separator
    var separator2 = HSeparator.new()
    separator2.add_theme_constant_override("separation", 12)
    vbox.add_child(separator2)
    
    # Audio section
    var audio_section = Label.new()
    audio_section.text = "Audio"
    audio_section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    audio_section.add_theme_font_size_override("font_size", 20)
    audio_section.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
    vbox.add_child(audio_section)
    
    # Master volume slider with label
    var volume_hbox = HBoxContainer.new()
    volume_hbox.add_theme_constant_override("separation", 10)
    vbox.add_child(volume_hbox)
    
    var volume_label = Label.new()
    volume_label.text = "Volume:"
    volume_label.custom_minimum_size = Vector2(80, 0)
    volume_label.add_theme_font_size_override("font_size", 16)
    volume_hbox.add_child(volume_label)
    
    var volume_slider = HSlider.new()
    volume_slider.min_value = 0.0
    volume_slider.max_value = 100.0
    volume_slider.value = 80.0
    volume_slider.custom_minimum_size = Vector2(100, 50)  # Increased height from 35 to 50 for better touch targets on Android
    volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    volume_slider.value_changed.connect(_on_volume_changed)
    volume_hbox.add_child(volume_slider)
    
    var volume_value = Label.new()
    volume_value.text = "80%"
    volume_value.custom_minimum_size = Vector2(50, 0)
    volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    volume_value.add_theme_font_size_override("font_size", 16)
    volume_slider.value_changed.connect(func(value): volume_value.text = "%d%%" % int(value))
    volume_hbox.add_child(volume_value)
    
    # Add a separator
    var separator3 = HSeparator.new()
    separator3.add_theme_constant_override("separation", 12)
    vbox.add_child(separator3)
    
    # Game section
    var game_section = Label.new()
    game_section.text = "Game"
    game_section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    game_section.add_theme_font_size_override("font_size", 20)
    game_section.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
    vbox.add_child(game_section)
    
    # Pause button (for mobile)
    var pause_button = Button.new()
    pause_button.text = "⏸ Pause Game"
    pause_button.custom_minimum_size = Vector2(0, 55)
    pause_button.add_theme_font_size_override("font_size", 18)
    pause_button.focus_mode = Control.FOCUS_NONE
    pause_button.add_theme_stylebox_override("normal", _create_styled_button_style(Color(0.35, 0.35, 0.25, 1.0), 8))
    pause_button.add_theme_stylebox_override("hover", _create_styled_button_style(Color(0.45, 0.45, 0.35, 1.0), 8))
    pause_button.add_theme_stylebox_override("pressed", _create_styled_button_style(Color(0.55, 0.55, 0.45, 1.0), 8))
    pause_button.pressed.connect(_on_pause_game_pressed)
    vbox.add_child(pause_button)
    
    # Add spacer
    var spacer = Control.new()
    spacer.custom_minimum_size = Vector2(0, 15)
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(spacer)
    
    # Close button
    var close_button = Button.new()
    close_button.text = "✕ Close"
    close_button.custom_minimum_size = Vector2(0, 50)
    close_button.add_theme_font_size_override("font_size", 20)
    close_button.focus_mode = Control.FOCUS_NONE
    
    # Style the close button
    close_button.add_theme_stylebox_override("normal", _create_styled_button_style(Color(0.5, 0.2, 0.2, 1.0), 8))
    close_button.add_theme_stylebox_override("hover", _create_styled_button_style(Color(0.6, 0.3, 0.3, 1.0), 8))
    close_button.add_theme_stylebox_override("pressed", _create_styled_button_style(Color(0.7, 0.4, 0.4, 1.0), 8))
    
    close_button.pressed.connect(_on_close_settings_pressed)
    vbox.add_child(close_button)
    
    add_child(settings_panel)
    DebugLogOverlay.add_log("Settings panel added to scene tree", "green")
    
    # Defer positioning to ensure viewport size is ready
    call_deferred("_update_settings_panel_position")

func _on_menu_button_pressed() -> void:
    DebugLogOverlay.add_log("Menu button pressed - opening pause menu", "yellow")
    
    # Instead of showing our own settings panel, open the pause menu
    # The pause menu has all the functionality working properly
    if pause_menu and pause_menu.has_method("toggle_pause"):
        pause_menu.toggle_pause()
        DebugLogOverlay.add_log("Pause menu opened", "green")
    else:
        DebugLogOverlay.add_log("Pause menu not found!", "red")

func _on_close_settings_pressed() -> void:
    DebugLogOverlay.add_log("Close settings button pressed", "yellow")
    
    # Hide settings panel
    settings_visible = false
    settings_panel.visible = false

func _on_camera_toggle_pressed() -> void:
    DebugLogOverlay.add_log("Camera toggle pressed", "yellow")
    
    # Toggle camera view on player and close menu (use cached reference)
    if player and player.has_method("_toggle_camera_view"):
        player._toggle_camera_view()
        DebugLogOverlay.add_log("Camera view toggled", "green")
    else:
        DebugLogOverlay.add_log("Player not found or method missing!", "red")
    
    # Close the settings menu after action
    _on_close_settings_pressed()

func _on_volume_changed(value: float) -> void:
    # Convert 0-100 to decibels (-40 to 0 dB)
    var db = linear_to_db(value / 100.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
    DebugLogOverlay.add_log("Volume changed to: %d%% (%.1f dB)" % [int(value), db], "cyan")

func _on_pause_game_pressed() -> void:
    DebugLogOverlay.add_log("Pause game button pressed", "yellow")
    
    # Close settings menu
    _on_close_settings_pressed()
    
    # Trigger pause menu (use cached reference)
    if pause_menu and pause_menu.has_method("toggle_pause"):
        pause_menu.toggle_pause()
        DebugLogOverlay.add_log("Pause menu toggled", "green")
    else:
        DebugLogOverlay.add_log("Pause menu not found!", "red")

func _update_button_position() -> void:
    if not menu_button:
        DebugLogOverlay.add_log("ERROR: menu_button is null in _update_button_position", "red")
        return
    
    # Position button in top-left corner, next to debug buttons
    # Place it to the right of the debug overlay buttons (which are at the very left)
    var viewport_size = get_viewport_rect().size
    var button_x = 100.0  # Position to the right of debug buttons (which take ~90px)
    var button_y = 10.0   # Small margin from top
    menu_button.position = Vector2(button_x, button_y)
    
    DebugLogOverlay.add_log("Menu button positioned at (%.0f, %.0f), viewport: %.0fx%.0f" % [button_x, button_y, viewport_size.x, viewport_size.y], "cyan")
    
    # Log absolute position after positioning
    if menu_button.is_inside_tree():
        var global_pos = menu_button.global_position
        DebugLogOverlay.add_log("Menu button global_position: (%.0f, %.0f)" % [global_pos.x, global_pos.y], "cyan")
        
        # Use helper function to check bounds and log results
        var bounds_check = _check_button_bounds(global_pos, viewport_size)
        _log_button_bounds_check(bounds_check)

func _check_button_bounds(button_global_pos: Vector2, viewport_size: Vector2) -> Dictionary:
    # Helper function to check if button is within viewport bounds
    # Note: Y position uses (BUTTON_SIZE/2) offset to align with joystick center,
    # so button may intentionally extend beyond viewport bottom edge
    var button_right = button_global_pos.x + BUTTON_SIZE
    var button_bottom = button_global_pos.y + BUTTON_SIZE
    
    var top_left_in_bounds = (button_global_pos.x >= 0 and button_global_pos.y >= 0 and 
                              button_global_pos.x < viewport_size.x and 
                              button_global_pos.y < viewport_size.y)
    var fully_in_bounds = (button_global_pos.x >= 0 and button_global_pos.y >= 0 and 
                           button_right <= viewport_size.x and 
                           button_bottom <= viewport_size.y)
    
    return {
        "top_left_in_bounds": top_left_in_bounds,
        "fully_in_bounds": fully_in_bounds,
        "button_right": button_right,
        "button_bottom": button_bottom
    }

func _log_button_bounds_check(bounds_check: Dictionary) -> void:
    # Helper function to log button bounds checking results with appropriate colors
    var top_left_color = "green" if bounds_check.top_left_in_bounds else "red"
    var fully_color = "green" if bounds_check.fully_in_bounds else "yellow"
    
    DebugLogOverlay.add_log("Button top-left in viewport: %s" % str(bounds_check.top_left_in_bounds), 
                            top_left_color)
    DebugLogOverlay.add_log("Button fully in viewport: %s (may extend beyond due to centering)" % str(bounds_check.fully_in_bounds), 
                            fully_color)

func _update_settings_panel_position() -> void:
    if not settings_panel:
        DebugLogOverlay.add_log("ERROR: settings_panel is null in _update_settings_panel_position", "red")
        return
    
    # Position panel below the menu button in the top-left area
    var viewport_size = get_viewport_rect().size
    
    # Position panel below the menu button with a small gap
    var panel_x = 10.0  # Small margin from left edge
    var panel_y = 70.0  # Below the menu button (which is at y=10 with size=60)
    
    settings_panel.position = Vector2(panel_x, panel_y)
    settings_panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
    
    DebugLogOverlay.add_log("Settings panel positioned at (%.0f, %.0f), size: %.0fx%.0f" % [panel_x, panel_y, PANEL_WIDTH, PANEL_HEIGHT], "cyan")

func _log_control_info() -> void:
    # Log comprehensive information about the MobileControls control itself
    var viewport_size = get_viewport_rect().size
    
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
        
        # Calculate expected screen bounds using helper function
        var bounds_check = _check_button_bounds(menu_button.global_position, viewport_size)
        DebugLogOverlay.add_log("Button bounds: (%.0f, %.0f) to (%.0f, %.0f)" % [
            menu_button.global_position.x, menu_button.global_position.y,
            bounds_check.button_right, bounds_check.button_bottom
        ], "cyan")
        
        # Log visibility checks using helper
        _log_button_bounds_check(bounds_check)
