extends Control
class_name PauseMenu

# UI Elements
var panel: Panel
var vbox: VBoxContainer
var resume_button: Button
var settings_button: Button
var quit_button: Button
var title_label: Label

# Settings panel reference
var settings_panel: Panel
var settings_visible: bool = false

# Configuration
const PANEL_WIDTH: float = 400.0
const PANEL_HEIGHT: float = 500.0
const SETTINGS_PANEL_WIDTH: float = 400.0
const SETTINGS_PANEL_HEIGHT: float = 450.0

func _ready():
    # Add to PauseMenu group so other systems can find this node
    add_to_group("PauseMenu")
    
    # Hide by default
    visible = false
    
    # Create main pause panel
    _create_pause_panel()
    
    # Create settings panel
    _create_settings_panel()
    
    # Listen for pause input
    set_process_input(true)

func _input(event):
    if event.is_action_pressed("toggle_pause"):
        toggle_pause()

func toggle_pause():
    visible = not visible
    
    if visible:
        # Pause the game tree
        get_tree().paused = true
        # Ensure pause menu is not affected by pause
        process_mode = Node.PROCESS_MODE_ALWAYS
        # Hide settings when opening pause menu
        if settings_visible:
            _toggle_settings()
    else:
        # Resume the game
        get_tree().paused = false
        # Hide settings when closing pause menu
        if settings_visible:
            _toggle_settings()

func _create_pause_panel():
    # Create main panel
    panel = Panel.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
    panel.position = Vector2(-PANEL_WIDTH / 2, -PANEL_HEIGHT / 2)
    panel.z_index = 100  # Ensure it's above everything
    
    # Style the panel
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
    add_child(panel)
    
    # Add margin container
    var margin = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    panel.add_child(margin)
    
    # Create vertical box
    vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 15)
    margin.add_child(vbox)
    
    # Title
    title_label = Label.new()
    title_label.text = "⏸ PAUSED"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 36)
    title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    vbox.add_child(title_label)
    
    # Add separator
    var separator1 = HSeparator.new()
    separator1.add_theme_constant_override("separation", 20)
    vbox.add_child(separator1)
    
    # Add spacer
    var spacer1 = Control.new()
    spacer1.custom_minimum_size = Vector2(0, 20)
    vbox.add_child(spacer1)
    
    # Resume button
    resume_button = Button.new()
    resume_button.text = "▶ Resume Game"
    resume_button.custom_minimum_size = Vector2(0, 60)
    resume_button.add_theme_font_size_override("font_size", 22)
    resume_button.focus_mode = Control.FOCUS_NONE
    resume_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.2, 0.5, 0.2, 1.0), 8))
    resume_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.3, 0.6, 0.3, 1.0), 8))
    resume_button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.4, 0.7, 0.4, 1.0), 8))
    resume_button.pressed.connect(_on_resume_pressed)
    vbox.add_child(resume_button)
    
    # Settings button
    settings_button = Button.new()
    settings_button.text = "⚙ Settings"
    settings_button.custom_minimum_size = Vector2(0, 60)
    settings_button.add_theme_font_size_override("font_size", 22)
    settings_button.focus_mode = Control.FOCUS_NONE
    settings_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.3, 0.3, 0.4, 1.0), 8))
    settings_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.4, 0.4, 0.5, 1.0), 8))
    settings_button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.5, 0.5, 0.6, 1.0), 8))
    settings_button.pressed.connect(_on_settings_pressed)
    vbox.add_child(settings_button)
    
    # Quit button
    quit_button = Button.new()
    quit_button.text = "⏹ Quit to Desktop"
    quit_button.custom_minimum_size = Vector2(0, 60)
    quit_button.add_theme_font_size_override("font_size", 22)
    quit_button.focus_mode = Control.FOCUS_NONE
    quit_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.5, 0.2, 0.2, 1.0), 8))
    quit_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.6, 0.3, 0.3, 1.0), 8))
    quit_button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.7, 0.4, 0.4, 1.0), 8))
    quit_button.pressed.connect(_on_quit_pressed)
    vbox.add_child(quit_button)
    
    # Add spacer
    var spacer2 = Control.new()
    spacer2.custom_minimum_size = Vector2(0, 20)
    spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(spacer2)
    
    # Info label
    var info_label = Label.new()
    info_label.text = "Press ESC to resume"
    info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_label.add_theme_font_size_override("font_size", 16)
    info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
    vbox.add_child(info_label)

func _create_settings_panel():
    # Create settings panel
    settings_panel = Panel.new()
    settings_panel.set_anchors_preset(Control.PRESET_CENTER)
    settings_panel.size = Vector2(SETTINGS_PANEL_WIDTH, SETTINGS_PANEL_HEIGHT)
    settings_panel.position = Vector2(-SETTINGS_PANEL_WIDTH / 2, -SETTINGS_PANEL_HEIGHT / 2)
    settings_panel.z_index = 101  # Above pause menu
    settings_panel.visible = false
    
    # Style the panel
    var panel_style = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.18, 0.18, 0.18, 0.95)
    panel_style.corner_radius_top_left = 15
    panel_style.corner_radius_top_right = 15
    panel_style.corner_radius_bottom_left = 15
    panel_style.corner_radius_bottom_right = 15
    panel_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
    panel_style.border_width_left = 3
    panel_style.border_width_right = 3
    panel_style.border_width_top = 3
    panel_style.border_width_bottom = 3
    settings_panel.add_theme_stylebox_override("panel", panel_style)
    add_child(settings_panel)
    
    # Add margin container
    var margin = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    settings_panel.add_child(margin)
    
    # Create vertical box
    var settings_vbox = VBoxContainer.new()
    settings_vbox.add_theme_constant_override("separation", 12)
    margin.add_child(settings_vbox)
    
    # Title
    var settings_title = Label.new()
    settings_title.text = "⚙ Settings"
    settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    settings_title.add_theme_font_size_override("font_size", 28)
    settings_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    settings_vbox.add_child(settings_title)
    
    # Separator
    var sep1 = HSeparator.new()
    settings_vbox.add_child(sep1)
    
    # Audio section
    var audio_label = Label.new()
    audio_label.text = "Audio"
    audio_label.add_theme_font_size_override("font_size", 20)
    audio_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
    settings_vbox.add_child(audio_label)
    
    # Master volume slider
    var master_hbox = HBoxContainer.new()
    master_hbox.add_theme_constant_override("separation", 10)
    settings_vbox.add_child(master_hbox)
    
    var master_label = Label.new()
    master_label.text = "Master Volume:"
    master_label.custom_minimum_size = Vector2(150, 0)
    master_label.add_theme_font_size_override("font_size", 16)
    master_hbox.add_child(master_label)
    
    var master_slider = HSlider.new()
    master_slider.min_value = 0.0
    master_slider.max_value = 100.0
    master_slider.value = 80.0
    master_slider.custom_minimum_size = Vector2(150, 0)
    master_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    master_slider.value_changed.connect(_on_master_volume_changed)
    master_hbox.add_child(master_slider)
    
    var master_value = Label.new()
    master_value.text = "80%"
    master_value.custom_minimum_size = Vector2(50, 0)
    master_value.add_theme_font_size_override("font_size", 16)
    master_slider.value_changed.connect(func(value): master_value.text = "%d%%" % int(value))
    master_hbox.add_child(master_value)
    
    # Separator
    var sep2 = HSeparator.new()
    settings_vbox.add_child(sep2)
    
    # Display section
    var display_label = Label.new()
    display_label.text = "Display"
    display_label.add_theme_font_size_override("font_size", 20)
    display_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
    settings_vbox.add_child(display_label)
    
    # Camera toggle
    var camera_button = Button.new()
    camera_button.text = "👁 Toggle First Person View"
    camera_button.custom_minimum_size = Vector2(0, 45)
    camera_button.add_theme_font_size_override("font_size", 18)
    camera_button.focus_mode = Control.FOCUS_NONE
    camera_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.3, 0.3, 0.3, 1.0), 5))
    camera_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.4, 0.4, 0.4, 1.0), 5))
    camera_button.pressed.connect(_on_camera_toggle_pressed)
    settings_vbox.add_child(camera_button)
    
    # Ruler toggle
    var ruler_hbox = HBoxContainer.new()
    ruler_hbox.add_theme_constant_override("separation", 10)
    settings_vbox.add_child(ruler_hbox)
    
    var ruler_checkbox = CheckBox.new()
    ruler_checkbox.button_pressed = true  # Initially visible
    ruler_checkbox.custom_minimum_size = Vector2(30, 30)
    ruler_checkbox.focus_mode = Control.FOCUS_NONE
    ruler_checkbox.toggled.connect(_on_ruler_toggled)
    ruler_hbox.add_child(ruler_checkbox)
    
    var ruler_label = Label.new()
    ruler_label.text = "Show Ruler"
    ruler_label.add_theme_font_size_override("font_size", 16)
    ruler_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    ruler_hbox.add_child(ruler_label)
    
    # Spacer
    var spacer = Control.new()
    spacer.custom_minimum_size = Vector2(0, 10)
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    settings_vbox.add_child(spacer)
    
    # Back button
    var back_button = Button.new()
    back_button.text = "← Back"
    back_button.custom_minimum_size = Vector2(0, 50)
    back_button.add_theme_font_size_override("font_size", 20)
    back_button.focus_mode = Control.FOCUS_NONE
    back_button.add_theme_stylebox_override("normal", _create_button_style(Color(0.3, 0.3, 0.3, 1.0), 8))
    back_button.add_theme_stylebox_override("hover", _create_button_style(Color(0.4, 0.4, 0.4, 1.0), 8))
    back_button.pressed.connect(_toggle_settings)
    settings_vbox.add_child(back_button)

func _create_button_style(bg_color: Color, corner_radius: int) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.corner_radius_top_left = corner_radius
    style.corner_radius_top_right = corner_radius
    style.corner_radius_bottom_left = corner_radius
    style.corner_radius_bottom_right = corner_radius
    return style

func _on_resume_pressed():
    toggle_pause()

func _on_settings_pressed():
    _toggle_settings()

func _toggle_settings():
    settings_visible = not settings_visible
    settings_panel.visible = settings_visible
    panel.visible = not settings_visible

func _on_quit_pressed():
    get_tree().quit()

func _on_master_volume_changed(value: float):
    # Convert 0-100 to decibels (-40 to 0 dB)
    var db = linear_to_db(value / 100.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_camera_toggle_pressed():
    # Find player and toggle camera
    var player = get_tree().get_first_node_in_group("Player")
    if player and player.has_method("_toggle_camera_view"):
        player._toggle_camera_view()

func _on_ruler_toggled(pressed: bool):
    # Find ruler overlay and toggle its visibility
    var ruler = get_tree().get_first_node_in_group("RulerOverlay")
    if ruler and ruler.has_method("set_visible_state"):
        ruler.set_visible_state(pressed)
