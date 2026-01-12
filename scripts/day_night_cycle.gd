extends Node3D
class_name DayNightCycle

# Day/night cycle configuration
const DAY_CYCLE_DURATION: float = 30.0 * 60.0  # 30 minutes in seconds
const SUNRISE_DURATION: float = 60.0  # 1 minute sunrise animation
const SUNSET_DURATION: float = 60.0  # 1 minute sunset animation
const SLEEP_LOCKOUT_DURATION: float = 4.0 * 60.0 * 60.0  # 4 hours in seconds
const WARNING_TIME_2MIN: float = 2.0 * 60.0  # 2 minutes before sunset
const WARNING_TIME_1MIN: float = 1.0 * 60.0  # 1 minute before sunset

# Debug mode for faster testing
@export var debug_mode: bool = false  # When true, time runs 60x faster
@export var debug_skip_lockout: bool = false  # When true, skip the 4-hour lockout

# Time tracking
var current_time: float = 0.0  # Current time in the day cycle (0 to DAY_CYCLE_DURATION)
var is_night: bool = false
var is_locked_out: bool = false
var lockout_end_time: float = 0.0  # Unix timestamp when lockout ends

# Warning states
var warning_2min_shown: bool = false
var warning_1min_shown: bool = false

# Animation states
var is_animating_sunrise: bool = false
var sunrise_animation_time: float = 0.0
var is_animating_sunset: bool = false
var sunset_animation_time: float = 0.0

# References
var directional_light: DirectionalLight3D
var world_environment: WorldEnvironment
var ui_manager: Node
var player: Node3D

# Save file path
const SAVE_FILE_PATH: String = "user://day_night_save.cfg"

func _ready():
    # Find references
    directional_light = get_tree().get_first_node_in_group("DirectionalLight3D")
    if not directional_light:
        directional_light = get_parent().get_node_or_null("DirectionalLight3D")
    
    world_environment = get_tree().get_first_node_in_group("WorldEnvironment")
    if not world_environment:
        world_environment = get_parent().get_node_or_null("WorldEnvironment")
    
    ui_manager = get_parent().get_node_or_null("UIManager")
    player = get_tree().get_first_node_in_group("Player")
    if not player:
        player = get_parent().get_node_or_null("Player")
    
    # Load saved state
    _load_state()
    
    # Check if we need to show sunrise animation
    if is_locked_out:
        var current_unix_time = Time.get_unix_time_from_system()
        if current_unix_time >= lockout_end_time:
            # Lockout has expired, show sunrise animation
            is_locked_out = false
            is_animating_sunrise = true
            sunrise_animation_time = 0.0
            current_time = 0.0  # Start of new day
            _disable_player_input()
        else:
            # Still in lockout, show night screen
            is_night = true
            _show_night_screen()
            _set_night_lighting()
    else:
        # Normal day start
        _update_lighting()

func _process(delta):
    # Apply debug time multiplier
    var time_delta = delta
    if debug_mode:
        time_delta *= 60.0  # 60x faster for testing
    
    # Handle lockout check
    if is_locked_out and not is_night:
        var current_unix_time = Time.get_unix_time_from_system()
        # Skip lockout if debug mode is enabled
        if debug_skip_lockout or current_unix_time >= lockout_end_time:
            # Time to wake up, show sunrise
            is_locked_out = false
            is_animating_sunrise = true
            sunrise_animation_time = 0.0
            current_time = 0.0
            _disable_player_input()
            _hide_night_screen()
        return
    
    # Handle sunrise animation
    if is_animating_sunrise:
        sunrise_animation_time += time_delta
        var progress = sunrise_animation_time / SUNRISE_DURATION
        
        if progress >= 1.0:
            # Sunrise complete
            is_animating_sunrise = false
            sunrise_animation_time = 0.0
            _enable_player_input()
        else:
            _animate_sunrise(progress)
        return
    
    # Handle sunset animation
    if is_animating_sunset:
        sunset_animation_time += time_delta
        var progress = sunset_animation_time / SUNSET_DURATION
        
        if progress >= 1.0:
            # Sunset complete, enter night
            is_animating_sunset = false
            sunset_animation_time = 0.0
            is_night = true
            is_locked_out = true
            lockout_end_time = Time.get_unix_time_from_system() + SLEEP_LOCKOUT_DURATION
            _save_state()
            _show_night_screen()
            _set_night_lighting()
            _disable_player_input()
        else:
            _animate_sunset(progress)
        return
    
    # Normal day progression
    if not is_night:
        current_time += time_delta
        
        # Check for warnings
        var time_until_sunset = DAY_CYCLE_DURATION - current_time
        
        if time_until_sunset <= WARNING_TIME_2MIN and not warning_2min_shown:
            warning_2min_shown = true
            _show_warning("2 minutes until sunset! Find a place to sleep.")
        
        if time_until_sunset <= WARNING_TIME_1MIN and not warning_1min_shown:
            warning_1min_shown = true
            _show_warning("1 minute until sunset! Find a place to sleep NOW!")
        
        # Check if sunset should start
        if current_time >= DAY_CYCLE_DURATION:
            is_animating_sunset = true
            sunset_animation_time = 0.0
            warning_2min_shown = false
            warning_1min_shown = false
        else:
            _update_lighting()

func _update_lighting():
    if not directional_light:
        return
    
    # Calculate sun angle based on current time
    # 0 = sunrise, DAY_CYCLE_DURATION/2 = noon, DAY_CYCLE_DURATION = sunset
    var time_ratio = current_time / DAY_CYCLE_DURATION
    
    # Sun moves from east (-90°) to west (90°) over the course of the day
    # At noon, sun is directly overhead (0°)
    var sun_angle = lerp(-90.0, 90.0, time_ratio)
    
    # Apply rotation to directional light
    # Rotate around X axis for sun elevation
    directional_light.rotation_degrees.x = -sun_angle
    
    # Adjust light intensity based on time of day
    # Brightest at noon, dimmer at sunrise/sunset
    var intensity_curve = 1.0 - abs(time_ratio - 0.5) * 2.0  # 0 at edges, 1 at center
    directional_light.light_energy = lerp(0.6, 1.5, intensity_curve)
    
    # Adjust ambient light color
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        var color_warmth = lerp(0.2, 0.0, intensity_curve)  # More orange at sunrise/sunset
        env.ambient_light_color = Color(1.0, 1.0 - color_warmth, 1.0 - color_warmth * 1.5)

func _animate_sunrise(progress: float):
    if not directional_light:
        return
    
    # Animate from night (below horizon) to day (above horizon)
    var sun_angle = lerp(-120.0, -30.0, progress)  # Start below horizon, rise to morning position
    directional_light.rotation_degrees.x = -sun_angle
    
    # Fade in light
    directional_light.light_energy = lerp(0.0, 0.8, progress)
    
    # Adjust colors - start with warm sunrise colors
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        var warmth = lerp(0.4, 0.1, progress)
        env.ambient_light_color = Color(1.0, 1.0 - warmth, 1.0 - warmth * 1.5)

func _animate_sunset(progress: float):
    if not directional_light:
        return
    
    # Animate from day to night (sun going below horizon)
    var sun_angle = lerp(30.0, 120.0, progress)  # Descend below horizon
    directional_light.rotation_degrees.x = -sun_angle
    
    # Fade out light
    directional_light.light_energy = lerp(0.8, 0.0, progress)
    
    # Adjust colors - warm sunset colors
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        var warmth = lerp(0.1, 0.5, progress * 0.7)  # Get warmer during sunset
        env.ambient_light_color = Color(1.0, 1.0 - warmth, 1.0 - warmth * 1.5)

func _set_night_lighting():
    if not directional_light:
        return
    
    # Set sun below horizon
    directional_light.rotation_degrees.x = 120.0
    directional_light.light_energy = 0.0
    
    # Dark blue ambient light for night
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.ambient_light_color = Color(0.1, 0.1, 0.2)

func _show_warning(message: String):
    if ui_manager and ui_manager.has_method("show_message"):
        ui_manager.show_message(message, 5.0)

func _show_night_screen():
    if ui_manager and ui_manager.has_method("show_night_overlay"):
        ui_manager.show_night_overlay(lockout_end_time)

func _hide_night_screen():
    if ui_manager and ui_manager.has_method("hide_night_overlay"):
        ui_manager.hide_night_overlay()

func _disable_player_input():
    if player and player.has_method("set_input_enabled"):
        player.set_input_enabled(false)

func _enable_player_input():
    if player and player.has_method("set_input_enabled"):
        player.set_input_enabled(true)

func _save_state():
    var config = ConfigFile.new()
    config.set_value("day_night", "is_locked_out", is_locked_out)
    config.set_value("day_night", "lockout_end_time", lockout_end_time)
    config.set_value("day_night", "current_time", current_time)
    
    var error = config.save(SAVE_FILE_PATH)
    if error != OK:
        push_warning("Failed to save day/night state: " + str(error))

func _load_state():
    var config = ConfigFile.new()
    var error = config.load(SAVE_FILE_PATH)
    
    if error == OK:
        is_locked_out = config.get_value("day_night", "is_locked_out", false)
        lockout_end_time = config.get_value("day_night", "lockout_end_time", 0.0)
        current_time = config.get_value("day_night", "current_time", 0.0)
    else:
        # No save file or error loading, use defaults
        is_locked_out = false
        lockout_end_time = 0.0
        current_time = 0.0
